//
//  AlloyTests.swift
//  AlloyTests
//
//  Created by Andrey Volodin on 20/01/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import XCTest
import Alloy
import MetalKit

class AlloyTests: XCTestCase {

    var context: MTLContext! = nil

    var evenInitState: MTLComputePipelineState! = nil
    var evenOptimizedInitState: MTLComputePipelineState! = nil
    var exactInitState: MTLComputePipelineState! = nil

    var evenProcessState: MTLComputePipelineState! = nil
    var evenOptimizedProcessState: MTLComputePipelineState! = nil
    var exactProcessState: MTLComputePipelineState! = nil

    var textureBaseWidth = 1024
    var textureBaseHeight = 1024
    var gpuIterations = 4

    override func setUp() {
        self.context = MTLContext(device: Metal.device)

        guard let library = self.context.shaderLibrary(for: AlloyTests.self) ?? self.context.standardLibrary else {
            fatalError("Could not load shader library")
        }

        self.evenInitState = try! library.computePipelineState(function: "initialize_even")

        let computeStateDescriptor = MTLComputePipelineDescriptor()
        computeStateDescriptor.computeFunction = library.makeFunction(name: "initialize_even")!
        computeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

        self.evenOptimizedInitState = try! self.context
                                               .device
                                               .makeComputePipelineState(descriptor: computeStateDescriptor,
                                                                         options: [],
                                                                         reflection: nil)

        self.exactInitState = try! library.computePipelineState(function: "initialize_exact")

        self.evenProcessState = try! library.computePipelineState(function: "process_even")

        let processComputeStateDescriptor = MTLComputePipelineDescriptor()
        processComputeStateDescriptor.computeFunction = library.makeFunction(name: "process_even")!
        processComputeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

        self.evenOptimizedProcessState = try! self.context
            .device
            .makeComputePipelineState(descriptor: processComputeStateDescriptor,
                                      options: [],
                                      reflection: nil)

        self.exactProcessState = try! library.computePipelineState(function: "process_exact")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEvenPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, outputTexture) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.evenInitState, covering: texture.size)

                encoder.setTexture(outputTexture, index: 1)
                encoder.dispatch2d(state: self.evenProcessState, covering: texture.size)
            }
        }
    }

    func testEvenOptimizedPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, outputTexture) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.evenOptimizedInitState, covering: texture.size)

                encoder.setTexture(outputTexture, index: 1)
                encoder.dispatch2d(state: self.evenOptimizedProcessState, covering: texture.size)
            }
        }
    }

    func testExactPerformance() {
        self.measure {
            self.runGPUWork { (encoder, texture, outputTexture) in
                encoder.setTexture(texture, index: 0)
                encoder.dispatch2d(state: self.exactInitState, exactly: texture.size)

                encoder.setTexture(outputTexture, index: 1)
                encoder.dispatch2d(state: self.exactProcessState, exactly: texture.size)
            }
        }
    }

    func runGPUWork(encoding: (MTLComputeCommandEncoder, MTLTexture, MTLTexture) -> Void) {
        do {
            let maximumThreadgroupSize = evenInitState.max2dThreadgroupSize

            var totalGPUTime: CFTimeInterval = 0
            var iterations = 0

            for wd in 0..<maximumThreadgroupSize.width {
                for ht in 0..<maximumThreadgroupSize.height {
                    var texture = self.context.texture(width:  self.textureBaseWidth + wd,
                                                       height: self.textureBaseHeight + ht,
                                                       pixelFormat: .rgba8Unorm)!

                    var outputTexture = self.context.texture(width:  self.textureBaseWidth + wd,
                                                             height: self.textureBaseHeight + ht,
                                                             pixelFormat: .rgba8Unorm)!

                    try self.context.scheduleAndWait { buffer in
                        buffer.compute { encoder in
                            for _ in 0...self.gpuIterations {
                                encoding(encoder, texture, outputTexture)

                                swap(&texture, &outputTexture)
                            }
                        }

                        buffer.addCompletedHandler { buffer in
                            if #available(iOS 10.3, tvOS 10.3, *) {
                                iterations += 1
                                totalGPUTime += buffer.gpuExecutionTime
                            }
                        }
                    }
                }

            }

            print("\(#function) average GPU Time: \(totalGPUTime / CFTimeInterval(iterations))")
        }

        catch { fatalError(error.localizedDescription) }
    }
}

class IdealSizeTests: XCTestCase {
    var context: MTLContext!

    var evenState: MTLComputePipelineState! = nil
    var evenOptimizedState: MTLComputePipelineState! = nil
    var exactState: MTLComputePipelineState! = nil

    var textureBaseMultiplier = 16
    var gpuIterations = 256

    override func setUp() {
        self.context = MTLContext(device: Metal.device)

        guard let library = self.context.shaderLibrary(for: IdealSizeTests.self) ?? self.context.standardLibrary else {
            fatalError("Could not load shader library")
        }

        self.evenState = try! library.computePipelineState(function: "fill_with_threadgroup_size_even")

        let computeStateDescriptor = MTLComputePipelineDescriptor()
        computeStateDescriptor.computeFunction = library.makeFunction(name: "fill_with_threadgroup_size_even")!
        computeStateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

        self.evenOptimizedState = try! self.context
            .device
            .makeComputePipelineState(descriptor: computeStateDescriptor,
                                      options: [],
                                      reflection: nil)

        self.exactState = try! library.computePipelineState(function: "fill_with_threadgroup_size_exact")
    }

    func testSpeedOnIdealSize() {
        do {
            var bestTimeCounter: [String: Int] = [:]

            for _ in 1...self.gpuIterations {
                let size = self.evenState.max2dThreadgroupSize
                let texture = self.context.texture(width: size.width * self.textureBaseMultiplier,
                                                   height: size.height * self.textureBaseMultiplier,
                                                   pixelFormat: .rg16Uint,
                                                   usage: .shaderWrite)!

                var results = [(String, CFTimeInterval)]()

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.evenState, covering: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Even", buffer.gpuExecutionTime))
                    })
                }

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.evenOptimizedState, covering: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Even optimized", buffer.gpuExecutionTime))
                    })
                }

                try self.context.scheduleAndWait { buffer in
                    buffer.compute { encoder in
                        encoder.setTexture(texture, index: 0)
                        encoder.dispatch2d(state: self.exactState, exactly: texture.size)
                    }

                    buffer.addCompletedHandler({ buffer in
                        results.append(("Exact", buffer.gpuExecutionTime))
                    })
                }

                results.sort { $0.1 < $1.1 }
                bestTimeCounter[results.first!.0, default: 0] += 1
            }

            print(bestTimeCounter)
        }

        catch { fatalError(error.localizedDescription) }
    }

}

class EuclideanDistanceTests: XCTestCase {

    // MARK: - Errors

    enum Errors: Error {
        case cgImageCreationFailed
        case textureCreationFailed
        case bufferCreationFailed
    }

    // MARK: - Properties

    private var metalContext: MTLContext!
    private var euclideanDistanceFloat: EuclideanDistanceEncoder!
    private var textureAddConstantFloat: TextureAddConstantEncoder!

    // MARK: - Setup

    override func setUp() {
        do {
            self.metalContext = .init(device: Metal.device)
            self.euclideanDistanceFloat = try .init(metalContext: self.metalContext,
                                                    scalarType: .float)
            self.textureAddConstantFloat = try .init(metalContext: self.metalContext,
                                                     scalarType: .float)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testEuclideanDistance() {
        do {
            var zeroValue = Float()
            guard let resultBuffer = self.metalContext
                                         .device
                                         .makeBuffer(bytes: &zeroValue,
                                                     length: MemoryLayout<Float>.stride,
                                                     options: .storageModeShared)
            else { throw Errors.bufferCreationFailed }

            let image = #imageLiteral(resourceName: "255")
            guard let cgImage = image.cgImage
            else { throw Errors.cgImageCreationFailed }
            let originalTexture = try self.metalContext
                                          .texture(from: cgImage,
                                                   usage: [.shaderRead, .shaderWrite])
            guard let modifiedTexture = originalTexture.matchingTexture()
            else { throw Errors.textureCreationFailed }

            let constant = Float(-0.1)
            let euclideanDistance = Float(originalTexture.width * originalTexture.height) * sqrt(4 * (pow(constant, 2)))

            try self.metalContext.scheduleAndWait { commandBuffer in
                self.textureAddConstantFloat.encode(sourceTexture: originalTexture,
                                                    destinationTexture: modifiedTexture,
                                                    constant: .init(-0.1),
                                                    in: commandBuffer)

                self.euclideanDistanceFloat.encode(textureOne: originalTexture,
                                                   textureTwo: modifiedTexture,
                                                   resultBuffer: resultBuffer,
                                                   in: commandBuffer)
            }

            let result = resultBuffer.pointer(of: Float.self)!.pointee
            let diff = abs(result - euclideanDistance)

            XCTAssert(diff < 40)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}

class TextureCachingTests: XCTestCase {

    // MARK: - Errors

    enum Errors: Error {
        case cgImageCreationFailed
        case textureCreationFailed
        case libraryCreationFailed
        case bufferCreationFailed
        case unsutablePixelFormat
    }

    // MARK: - Properties

    private var metalContext: MTLContext!
    private var euclideanDistanceFloat: EuclideanDistanceEncoder!
    private var euclideanDistanceUInt: EuclideanDistanceEncoder!
    private var denormalize: SwitchDataFormatEncoder!

    // MARK: - Setup

    override func setUp() {
        do {
            self.metalContext = .init(device: Metal.device)

            guard
                let alloyLibrary = self.metalContext
                                       .shaderLibrary(for: EuclideanDistanceEncoder.self),
                let alloyTestsLibrary = self.metalContext
                                            .shaderLibrary(for: SwitchDataFormatEncoder.self)
            else { throw Errors.libraryCreationFailed }

            self.euclideanDistanceFloat = try .init(library: alloyLibrary,
                                                    scalarType: .float)
            self.euclideanDistanceUInt = try .init(library: alloyLibrary,
                                                   scalarType: .uint)
            self.denormalize = try .init(library: alloyTestsLibrary,
                                         conversionType: .denormalize)
        } catch {
            fatalError(error.localizedDescription)
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
            fatalError(error.localizedDescription)
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
        guard let resultBuffer = self.metalContext
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
            try self.metalContext.scheduleAndWait { commadBuffer in
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
            let decodedTexture = try decodedTextureCodableBox.texture(device: self.metalContext.device)

            try self.metalContext.scheduleAndWait { commadBuffer in

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
            resultTexture = try self.metalContext.texture(from: cgImage,
                                                          usage: [.shaderRead, .shaderWrite],
                                                          generateMipmaps: generateMipmaps)
        case .unsignedInteger:
            generateMipmaps = false

            let normalizedTexture = try self.metalContext.texture(from: cgImage,
                                                                  usage: [.shaderRead, .shaderWrite])

            let unnormalizedTextureDescriptor = MTLTextureDescriptor()
            unnormalizedTextureDescriptor.width = cgImage.width
            unnormalizedTextureDescriptor.height = cgImage.height
            unnormalizedTextureDescriptor.pixelFormat = pixelFormat
            unnormalizedTextureDescriptor.usage = [.shaderRead, .shaderWrite]
            unnormalizedTextureDescriptor.storageMode = .shared

            guard let unnormalizedTexture = self.metalContext
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
