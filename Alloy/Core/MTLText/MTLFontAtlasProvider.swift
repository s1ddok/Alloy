#if os(iOS)

import Foundation
import UIKit
import Metal
import MetalPerformanceShaders

final public class MTLFontAtlasProvider {

    public enum Error: Swift.Error {
        case fontCreationFailed
    }

    // MARK: - Properties

    public let context: MTLContext

    private let quantizeDistanceField: QuantizeDistanceField
    private let scale: MPSImageBilinearScale
    private let sourceFontAtlasSize = 4096
    private var atlasCache: [MTLFontAtlasDescriptor: MTLFontAtlas] = [:]

    // MARK: - Init

    /// Create a signed-distance field based font atlas with the specified dimensions.
    /// The supplied font will be resized to fit all available glyphs in the texture.
    /// - Parameters:
    ///   - font: font.
    ///   - textureSize: texture size.
    public init(context: MTLContext) throws {
        self.context = context
        self.quantizeDistanceField = try .init(context: context)
        self.scale = .init(device: context.device)

        let defaultAtlas = try JSONDecoder().decode(MTLFontAtlasCodableBox.self,
                                                    from: .init(contentsOf: Self.defaultAtlasFileURL))
                                          .fontAtlas(device: context.device)
        self.atlasCache[Self.defaultAtlasDescriptor] = defaultAtlas
    }

    /// Provide font atlas
    /// - Parameter descriptor: font atlas descriptor.
    public func fontAtlas(descriptor: MTLFontAtlasDescriptor) throws -> MTLFontAtlas {
        if self.atlasCache[descriptor] == nil {
            self.atlasCache[descriptor] = try self.createAtlas(descriptor: descriptor)
        }
        return self.atlasCache[descriptor]!
    }

    private func createFontAtlasData(font: UIFont,
                                     width: Int,
                                     height: Int) -> (data: [UInt8],
                                                      descriptors: [GlyphDescriptor]) {
        var data = [UInt8](repeating: .zero,
                           count: width * height)
        var glyphDescriptors: [GlyphDescriptor] = []

        let context = CGContext(data: &data,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: width,
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGBitmapInfo.alphaInfoMask.rawValue & CGImageAlphaInfo.none.rawValue)!

        // Turn off antialiasing so we only get fully-on or fully-off pixels.
        // This implicitly disables subpixel antialiasing and hinting.
        context.setAllowsAntialiasing(false)

        // Flip context coordinate space so y increases downward
        context.translateBy(x: .zero,
                             y: .init(height))
        context.scaleBy(x: 1,
                        y: -1)

        let rect = CGRect(x: 0,
                          y: 0,
                          width: width,
                          height: height)

        // Fill the context with an opaque black color
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)

        let ctFont = font.ctFont
        let fontGlyphCount = CTFontGetGlyphCount(ctFont)
        let glyphMargin = font.estimatedLineWidth

        // Set fill color so that glyphs are solid white
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)

        let fontAscent = CTFontGetAscent(ctFont)
        let fontDescent = CTFontGetDescent(ctFont)

        var origin = CGPoint(x: 0, y: fontAscent)

        var maxYCoordForLine: CGFloat = -1

        let glyphIndices = (0 ..< fontGlyphCount).map { CGGlyph($0) }

        for var glyphIndex in glyphIndices {
            var boundingRect = CGRect()

            CTFontGetBoundingRectsForGlyphs(ctFont,
                                            .horizontal,
                                            &glyphIndex,
                                            &boundingRect,
                                            1)

            if (origin.x + boundingRect.maxX + glyphMargin) > .init(width) {
                origin.x = 0
                origin.y = maxYCoordForLine + glyphMargin + fontDescent
                maxYCoordForLine = -1
            }

            if (origin.y + boundingRect.maxY) > maxYCoordForLine {
                maxYCoordForLine = origin.y + boundingRect.maxY
            }

            let glyphOriginX = origin.x - boundingRect.origin.x + (glyphMargin * 0.5)
            let glyphOriginY = origin.y + (glyphMargin * 0.5)
            var glyphTransform = CGAffineTransform(a: 1,
                                                   b: 0,
                                                   c: 0,
                                                   d: -1,
                                                   tx: glyphOriginX,
                                                   ty: glyphOriginY)

            var glyphPathBoundingRect: CGRect = .zero

            if let path = CTFontCreatePathForGlyph(ctFont,
                                                   glyphIndex,
                                                   &glyphTransform) {

                context.addPath(path)
                context.fillPath()

                glyphPathBoundingRect = path.boundingBoxOfPath
            }

            let texCoordLeft: Float = .init(glyphPathBoundingRect.origin.x)
                                    / .init(width)
            let texCoordRight: Float = .init((glyphPathBoundingRect.origin.x + glyphPathBoundingRect.size.width))
                                     / .init(width)
            let texCoordTop: Float = .init((glyphPathBoundingRect.origin.y))
                                   / .init(height)
            let texCoordBottom: Float = .init((glyphPathBoundingRect.origin.y + glyphPathBoundingRect.size.height))
                                      / .init(height)

            let descriptor = GlyphDescriptor(glyphIndex: .init(glyphIndex),
                                             topLeftCoordinate: .init(x: texCoordLeft,
                                                                      y: texCoordTop),
                                             bottomRightCoordinate: .init(x: texCoordRight,
                                                                          y: texCoordBottom))
            glyphDescriptors.append(descriptor)

            origin.x += boundingRect.width + glyphMargin
        }

        return (data, glyphDescriptors)
    }

    /// Compute signed-distance field for an 8-bpp grayscale image (values greater than 127 are considered "on")
    /// For details of this algorithm, see "The 'dead reckoning' signed distance transform" [Grevera 2004]
    private func createSignedDistanceFieldData(from fontAtlasData: [UInt8],
                                               width: Int,
                                               height: Int) -> [Float] {
        let maxDist = hypot(Float(width), Float(height))
        // Initialization phase.
        // Distance to nearest boundary point map - set all distances to "infinity".
        var distanceMap = [Float](repeating: maxDist,
                                  count: width * height)
        // Nearest boundary point map - zero out nearest boundary point map.
        var boundaryPointMap = [SIMD2<Int32>](repeating: .zero,
                                              count: width * height)
        let distUnit: Float = 1
        let distDiag: Float = sqrtf(2)
        // Immediate interior/exterior phase: mark all points along the boundary as such.
        for y in 1 ..< (height - 1) {
            for x in 1 ..< (width - 1) {
                let inside = fontAtlasData[y * width + x] > 0x7f // aka 127
                if (fontAtlasData[y * width + x - 1] > 0x7f) != inside    ||
                    (fontAtlasData[y * width + x + 1] > 0x7f) != inside   ||
                    (fontAtlasData[(y - 1) * width + x] > 0x7f) != inside ||
                    (fontAtlasData[(y + 1) * width + x] > 0x7f) != inside {
                    distanceMap[y * width + x] = 0
                    boundaryPointMap[y * width + x].x = Int32(x)
                    boundaryPointMap[y * width + x].y = Int32(y)
                }
            }
        }
        // Forward dead-reckoning pass.
        for y in 1 ..< (height - 2) {
            for x in 1 ..< (width - 2) {
                var d: Float { distanceMap[y * width + x] }
                var n: SIMD2<Int32> { boundaryPointMap[y * width + x] }
                var h: Float { hypot(Float(x) - Float(n.x), Float(y) - Float(n.y)) }
                if distanceMap[(y - 1) * width + x - 1] + distDiag < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y - 1) * width + (x - 1)]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[(y - 1) * width + x] + distUnit < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y - 1) * width + x]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[(y - 1) * width + x + 1] + distDiag < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y - 1) * width + (x + 1)]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[y * width + x - 1] + distUnit < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[y * width + (x - 1)]
                    distanceMap[y * width + x] = h
                }
            }
        }
        // Backward dead-reckoning pass.
        for y in (1 ... (height - 2)).reversed() {
            for x in (1 ... (width - 2)).reversed() {
                var d: Float { distanceMap[y * width + x] }
                var n: SIMD2<Int32> { boundaryPointMap[y * width + x] }
                var h: Float { hypot(Float(x) - Float(n.x), Float(y) - Float(n.y)) }

                if distanceMap[y * width + x + 1] + distUnit < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[y * width + x + 1]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[(y + 1) * width + x - 1] + distDiag < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y + 1) * width + x - 1]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[(y + 1) * width + x] + distUnit < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y + 1) * width + x]
                    distanceMap[y * width + x] = h
                }
                if distanceMap[(y + 1) * width + x + 1] + distDiag < d {
                    boundaryPointMap[y * width + x] = boundaryPointMap[(y + 1) * width + x + 1]
                    distanceMap[y * width + x] = h
                }
            }
        }
        // Interior distance negation pass; distances outside the figure are considered negative.
        for y in 0..<height {
            for x in 0..<width {
                if fontAtlasData[y * width + x] <= 0x7f {
                    distanceMap[y * width + x] = -distanceMap[y * width + x]
                }
            }
        }
        return distanceMap
    }

    private func createAtlas(descriptor: MTLFontAtlasDescriptor) throws -> MTLFontAtlas {
        guard let font = UIFont.atlasFont(name: descriptor.fontName,
                                          atlasRect: .init(origin: .zero,
                                                           size: .init(width: self.sourceFontAtlasSize,
                                                                       height: self.sourceFontAtlasSize)))
        else { throw Error.fontCreationFailed }

        let fontAtlasData = self.createFontAtlasData(font: font,
                                                     width: self.sourceFontAtlasSize,
                                                     height: self.sourceFontAtlasSize)

        var sdfFontAtlasData = self.createSignedDistanceFieldData(from: fontAtlasData.data,
                                                                  width: self.sourceFontAtlasSize,
                                                                  height: self.sourceFontAtlasSize)

        let sdfFontAtlasTexture = try self.context
                                          .texture(width: self.sourceFontAtlasSize,
                                                   height: self.sourceFontAtlasSize,
                                                   pixelFormat: .r32Float,
                                                   usage: [.shaderRead, .shaderWrite])
        let fontAtlasTexture = try self.context
                                       .texture(width: descriptor.textureSize,
                                                height: descriptor.textureSize,
                                                pixelFormat: .r8Unorm,
                                                usage: [.shaderRead, .shaderWrite])

        let fontAtlas = MTLFontAtlas(font: font,
                                            glyphDescriptors: fontAtlasData.descriptors,
                                            fontAtlasTexture: fontAtlasTexture)

        sdfFontAtlasTexture.replace(region: sdfFontAtlasTexture.region,
                                    mipmapLevel: 0,
                                    withBytes: &sdfFontAtlasData,
                                    bytesPerRow: sdfFontAtlasTexture.width * MemoryLayout<Float>.stride)

        let fontSpread = Float(fontAtlas.font.estimatedLineWidth * 0.5)
        try self.context.scheduleAndWait { commandBuffer in
            self.quantizeDistanceField
                .encode(inPlaceSDFTexture: sdfFontAtlasTexture,
                        normalizationFactor: fontSpread,
                        in: commandBuffer)
            self.scale
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: sdfFontAtlasTexture,
                        destinationTexture: fontAtlas.fontAtlasTexture)

        }

        return fontAtlas
    }

    private static let defaultAtlasFileURL = Bundle(for: MTLFontAtlasProvider.self).url(forResource: "HelveticaNeue",
                                                                                        withExtension: "mtlfontatlas")!
    public static let defaultAtlasDescriptor = MTLFontAtlasDescriptor(fontName: "HelveticaNeue",
                                                                      textureSize: 2048)

}

#endif
