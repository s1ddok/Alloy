import XCTest
import Alloy
import MetalKit

final class TextureCachingTests: XCTestCase {

    // MARK: - Errors

    enum Error: Swift.Error {
        case cgImageCreationFailed
        case unsutablePixelFormat
    }

    // MARK: - Properties

    private var context: MTLContext!
    private var euclideanDistanceFloat: EuclideanDistance!
    private var euclideanDistanceUInt: EuclideanDistance!
    private var denormalize: SwitchDataFormatEncoder!

    // MARK: - Setup

    override func setUp() {
        do {
            self.context = try .init()
            self.euclideanDistanceFloat = try .init(context: self.context,
                                                    scalarType: .float)
            self.euclideanDistanceUInt = try .init(context: self.context,
                                                   scalarType: .uint)
            self.denormalize = try .init(context: self.context,
                                         conversionType: .denormalize)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testTextureCaching() {
        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }
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

        let resultBuffer = try self.context
                                   .buffer(for: Float.self,
                                           options: .storageModeShared)

        let image_255x121 = #imageLiteral(resourceName: "255")
        let image_512x512 = #imageLiteral(resourceName: "512")
        let image_1024x1024 = #imageLiteral(resourceName: "1024")
        let images = [image_255x121,
                      image_512x512,
                      image_1024x1024]

        var originalTextures: [MTLTexture] = []
        var results: [Float] = []

        // Create textures.
        try autoreleasepool {
            try self.context
                    .scheduleAndWait { commadBuffer in
                for image in images {
                    guard let cgImage = image.cgImage
                    else { throw Error.cgImageCreationFailed }
                    let texture = try self.createTexture(from: cgImage,
                                                         pixelFormat: pixelFormat,
                                                         generateMipmaps: true,
                                                         in: commadBuffer)
                    originalTextures.append(texture)
                }
            }
        }

        // Test
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

            results.append(resultBuffer.pointer(of: Float.self)!.pointee)
        }

        return results
    }

    private func createTexture(from cgImage: CGImage,
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

