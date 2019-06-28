//
//  MinEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14/02/2019.
//

import Metal
import simd

public class MinEncoder {

    public enum Errors: Error {
        case functionCreationFailed
        case encoderCreationFailed
        case invalidBufferStorageMode
    }

    let pipelineState: MTLComputePipelineState

    public init(library: MTLLibrary) throws {
        self.pipelineState = try library.computePipelineState(function: MinEncoder.functionName)
    }

    public func encode(inputTexture: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) throws {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: inputTexture.size)
        let blockSize = BlockSize(width: UInt16((inputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width),
                                  height: UInt16((inputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height))

        commandBuffer.compute { (encoder) in
            encoder.setTexture(inputTexture, index: 0)
            encoder.set(blockSize, at: 0)
            encoder.setBuffer(resultBuffer,
                              offset: 0,
                              index: 1)

            encoder.setThreadgroupMemoryLength(threadgroupSize.width * threadgroupSize.height * 4 * MemoryLayout<Float16>.stride,
                                               index: 0)
            encoder.dispatch2d(state: self.pipelineState,
                               covering: MTLSize(width: 1, height: 1, depth: 1),
                               threadgroupSize: threadgroupSize)
        }
    }

    public static let functionName = "min"
}
