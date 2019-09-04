//
//  TextureCachingTests.swift
//  Demo
//
//  Created by Eugene Bokhan on 04/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import XCTest
import Alloy
import MetalKit

final class TextureCachingTests: XCTestCase {

    // MARK: - Errors

    enum Errors: Error {
        case cgImageCreationFailed
        case textureCreationFailed
        case libraryCreationFailed
        case bufferCreationFailed
        case unsutablePixelFormat
    }

    // MARK: - Properties

    private var context: MTLContext!
    private var euclideanDistanceFloat: EuclideanDistanceEncoder!
    private var euclideanDistanceUInt: EuclideanDistanceEncoder!
    private var denormalize: SwitchDataFormatEncoder!

    // MARK: - Setup

    override func setUp() {
        do {
            self.context = .init(device: Metal.device)

            guard
                let alloyLibrary = self.context
                                       .shaderLibrary(for: EuclideanDistanceEncoder.self),
                let alloyTestsLibrary = self.context
                                            .shaderLibrary(for: SwitchDataFormatEncoder.self)
            else { throw Errors.libraryCreationFailed }

            self.euclideanDistanceFloat = try .init(library: alloyLibrary,
                                                    scalarType: .float)
            self.euclideanDistanceUInt = try .init(library: alloyLibrary,
                                                   scalarType: .uint)
            self.denormalize = try .init(library: alloyTestsLibrary,
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
        let euclideanDistance: EuclideanDistanceEncoder

        switch pixelFormat.dataFormat {
        case .normalized:
            euclideanDistance = self.euclideanDistanceFloat
        case .unsignedInteger:
            euclideanDistance = self.euclideanDistanceUInt
        default: throw Errors.unsutablePixelFormat
        }

        let jsonEncoder = JSONEncoder()
        let jsonDecoder = JSONDecoder()

        var zeroValue = Float()
        guard let resultBuffer = self.context
                                     .device
                                     .makeBuffer(bytes: &zeroValue,
                                                 length: MemoryLayout<Float>.stride,
                                                 options: .storageModeShared)
        else { throw Errors.bufferCreationFailed }

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
            try self.context.scheduleAndWait { commadBuffer in
                for image in images {
                    guard let cgImage = image.cgImage
                    else { throw Errors.cgImageCreationFailed }
                    let texture = try self.createTexture(from: cgImage,
                                                         pixelFormat: pixelFormat,
                                                         generateMipmaps: true,
                                                         in: commadBuffer)
                    originalTextures.append(texture)
                }
            }
        }

        // Test
        try originalTextures.forEach { originalTexture in
            let originalTextureCodableBox = try originalTexture.codable()
            let encodedData = try jsonEncoder.encode(originalTextureCodableBox)

            let decodedTextureCodableBox = try jsonDecoder.decode(MTLTextureCodableBox.self,
                                                                  from: encodedData)
            let decodedTexture = try decodedTextureCodableBox.texture(device: self.context.device)

            try self.context.scheduleAndWait { commadBuffer in

                if originalTexture.mipmapLevelCount > 1 {

                    var level: Int = 0
                    var width = originalTexture.width
                    var height = originalTexture.height

                    while (width + height > 32) {

                        guard
                            let originalTextureView = originalTexture.view(level: level),
                            let decodedTextureView = decodedTexture.view(level: level)
                        else { throw Errors.textureCreationFailed }

                        euclideanDistance.encode(textureOne: originalTextureView,
                                                 textureTwo: decodedTextureView,
                                                 resultBuffer: resultBuffer,
                                                 in: commadBuffer)

                        width = originalTextureView.width
                        height = originalTextureView.height
                        level += 1
                    }

                } else {
                    euclideanDistance.encode(textureOne: originalTexture,
                                             textureTwo: decodedTexture,
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
        let resultTexture: MTLTexture

        switch pixelFormat.dataFormat {
        case .normalized:
            resultTexture = try self.context.texture(from: cgImage,
                                                     usage: [.shaderRead, .shaderWrite],
                                                     generateMipmaps: generateMipmaps)
        case .unsignedInteger:
            generateMipmaps = false

            let normalizedTexture = try self.context.texture(from: cgImage,
                                                             usage: [.shaderRead, .shaderWrite])

            let unnormalizedTextureDescriptor = MTLTextureDescriptor()
            unnormalizedTextureDescriptor.width = cgImage.width
            unnormalizedTextureDescriptor.height = cgImage.height
            unnormalizedTextureDescriptor.pixelFormat = pixelFormat
            unnormalizedTextureDescriptor.usage = [.shaderRead, .shaderWrite]
            unnormalizedTextureDescriptor.storageMode = .shared

            guard let unnormalizedTexture = self.context
                                                .device
                                                .makeTexture(descriptor: unnormalizedTextureDescriptor)
            else { throw Errors.textureCreationFailed }

            self.denormalize.encode(normalizedTexture: normalizedTexture,
                                    unnormalizedTexture: unnormalizedTexture,
                                    in: commandBuffer)

            resultTexture = unnormalizedTexture
        default: throw Errors.unsutablePixelFormat
        }

        if generateMipmaps {
            commandBuffer.blit { encoder in
                encoder.generateMipmaps(for: resultTexture)
            }
        }

        return resultTexture
    }

}

