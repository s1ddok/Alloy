import XCTest
import Alloy
import AlloyTestsResources

final class TextureCachingTests: XCTestCase {

    // MARK: - Type Definitions

    enum Error: Swift.Error {
        case unsutablePixelFormat
    }

    // MARK: - Properties

    private var context: MTLContext!
    private var euclideanDistanceFloat: EuclideanDistance!
    private var euclideanDistanceUInt: EuclideanDistance!
    private var denormalize: SwitchDataFormatEncoder!

    // MARK: - Setup

    override func setUpWithError() throws {
        self.context = try .init()
        self.euclideanDistanceFloat = try .init(context: self.context,
                                                scalarType: .float)
        self.euclideanDistanceUInt = try .init(context: self.context,
                                               scalarType: .uint)
        self.denormalize = try .init(context: self.context,
                                     conversionType: .denormalize)
    }

    // MARK: - Testing

    func testTextureCaching() throws {
        let normalizedPixelFormats: [MTLPixelFormat] = [
            .rgba8Unorm, .rgba16Unorm, .rgba16Float, .rgba32Float
        ]
        let unsignedIntegerPixelFormats: [MTLPixelFormat] = [
            .rgba8Uint, .rgba16Uint, .rgba32Uint
        ]

        var results: [Float] = []

        try normalizedPixelFormats.forEach { results += try self.test(pixelFormat: $0) }
        try unsignedIntegerPixelFormats.forEach { results += try self.test(pixelFormat: $0) }

        let result = results.reduce(0, +)

        XCTAssert(result == 0)
    }

    private func test(pixelFormat: MTLPixelFormat) throws -> [Float] {
        let euclideanDistance: EuclideanDistance

        switch pixelFormat.dataFormat {
        case .normalized:
            euclideanDistance = self.euclideanDistanceFloat
        case .unsignedInteger:
            euclideanDistance = self.euclideanDistanceUInt
        default: throw Error.unsutablePixelFormat
        }

        let jsonEncoder = JSONEncoder()
        let jsonDecoder = JSONDecoder()

        let resultBuffer = try self.context.buffer(for: Float.self,
                                                   options: .storageModeShared)

        let originalTextures: [MTLTexture] = try ["255x121", "512x512", "1024x1024"].map {
            let originalTextureURL = Bundle.alloyTestsResources.url(forResource: "Shared/\($0)",
                                                                    withExtension: "png")!
            return try self.context.scheduleAndWait { commadBuffer in
                let cgImage = try CGImage.initFromURL(originalTextureURL)
                return try self.textureFromCGImage(cgImage,
                                                   pixelFormat: pixelFormat,
                                                   generateMipmaps: false,
                                                   in: commadBuffer)
            }
        }
        
        var results: [Float] = []

        try originalTextures.forEach { original in
            let originalTextureCodableBox = try original.codable()
            let encodedData = try jsonEncoder.encode(originalTextureCodableBox)

            let decodedTextureCodableBox = try jsonDecoder.decode(MTLTextureCodableBox.self,
                                                                  from: encodedData)
            let decoded = try decodedTextureCodableBox.texture(device: self.context.device)

            try self.context.scheduleAndWait { commadBuffer in
                if original.mipmapLevelCount > 1 {

                    var level: Int = 0
                    var width = original.width
                    var height = original.height

                    while (width + height > 32) {

                        guard let originalTextureView = original.view(level: level),
                              let decodedTextureView = decoded.view(level: level)
                        else { fatalError("Couldn't create texture view at level \(level)") }

                        euclideanDistance(textureOne: originalTextureView,
                                          textureTwo: decodedTextureView,
                                          resultBuffer: resultBuffer,
                                          in: commadBuffer)

                        width = originalTextureView.width
                        height = originalTextureView.height
                        level += 1
                    }

                } else {
                    euclideanDistance(textureOne: original,
                                      textureTwo: decoded,
                                      resultBuffer: resultBuffer,
                                      in: commadBuffer)
                }
            }
            
            let distance = resultBuffer.pointer(of: Float.self)!.pointee
            
            results.append(distance)
        }

        return results
    }

    private func textureFromCGImage(_ cgImage: CGImage,
                                    pixelFormat: MTLPixelFormat,
                                    generateMipmaps: Bool,
                                    in commandBuffer: MTLCommandBuffer) throws -> MTLTexture {
        var generateMipmaps = generateMipmaps
        let result: MTLTexture

        switch pixelFormat.dataFormat {
        case .normalized:
            result = try self.context.texture(from: cgImage,
                                              usage: [.shaderRead, .shaderWrite],
                                              generateMipmaps: generateMipmaps)
        case .unsignedInteger:
            generateMipmaps = false

            let normalized = try self.context.texture(from: cgImage,
                                                      usage: [.shaderRead, .shaderWrite])

            let unnormalizedTextureDescriptor = MTLTextureDescriptor()
            unnormalizedTextureDescriptor.width = cgImage.width
            unnormalizedTextureDescriptor.height = cgImage.height
            unnormalizedTextureDescriptor.pixelFormat = pixelFormat
            unnormalizedTextureDescriptor.usage = [.shaderRead, .shaderWrite]
            unnormalizedTextureDescriptor.storageMode = .shared

            let unnormalized = try self.context.texture(descriptor: unnormalizedTextureDescriptor)

            self.denormalize(normalized: normalized,
                             unnormalized: unnormalized,
                             in: commandBuffer)

            result = unnormalized
        default: throw Error.unsutablePixelFormat
        }

        if generateMipmaps {
            commandBuffer.blit { encoder in
                encoder.generateMipmaps(for: result)
            }
        }

        return result
    }

}
