//
//  MinEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14/02/2019.
//

import Metal
import simd

public class MinEncoder {

    enum Errors: Error {
        case functionCreationFailed
        case encoderCreationFailed
        case invalidBufferStorageMode
    }

    let pipelineState: MTLComputePipelineState

    public init(library: MTLLibrary) throws {
        self.pipelineState = try library.computePipelineState(function: MinEncoder.functionName)
    }

    public func encode(inputTexture: MTLTexture,
                       blockSize: BlockSize,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) throws {
        commandBuffer.compute { (encoder) in
            encoder.setTexture(inputTexture, index: 0)
            encoder.set(blockSize, at: 0)
            encoder.setBuffer(resultBuffer,
                              offset: 0,
                              index: 1)
            let threadgroupSize = self.pipelineState.max2dThreadgroupSize
            encoder.setThreadgroupMemoryLength(threadgroupSize.width * threadgroupSize.height * 4 * MemoryLayout<Float16>.stride,
                                               index: 0)
            encoder.dispatch2d(state: self.pipelineState,
                               covering: MTLSize(width: 1, height: 1, depth: 1))
        }
    }

    public static let functionName = "min"
}
