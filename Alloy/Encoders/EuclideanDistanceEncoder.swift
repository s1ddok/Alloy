//
//  EuclideanDistanceEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 30/08/2019.
//

import Metal

final public class EuclideanDistanceEncoder {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState

    // MARK: - Life Cycle

    convenience public init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.library(for: Self.self)
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library,
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let functionName = Self.functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName)
    }

    // MARK: - Encode

    public func encode(textureOne: MTLTexture,
                       textureTwo: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Euclidean Distance"
            self.encode(textureOne: textureOne,
                            textureTwo: textureTwo,
                            resultBuffer: resultBuffer,
                            using: encoder)
        }
    }

    public func encode(textureOne: MTLTexture,
                       textureTwo: MTLTexture,
                       resultBuffer: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: textureOne.size)
        let blockSize = BlockSize(width: .init((textureOne.width + threadgroupSize.width - 1) / threadgroupSize.width),
                                  height: .init((textureOne.height + threadgroupSize.height - 1) / threadgroupSize.height))

        encoder.set(textures: [textureOne, textureTwo])
        encoder.set(blockSize, at: 0)
        encoder.setBuffer(resultBuffer,
                          offset: 0,
                          index: 1)

        encoder.setThreadgroupMemoryLength(threadgroupSize.width * threadgroupSize.height * 4 * MemoryLayout<Float16>.stride,
                                           index: 0)
        encoder.dispatch2d(state: self.pipelineState,
                           covering: .one,
                           threadgroupSize: threadgroupSize)
    }

    public static let functionName = "euclideanDistance"
}
