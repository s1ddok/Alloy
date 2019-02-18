//
//  MaxEncoder.swift
//  Adjuster
//
//  Created by Eugene Bokhan on 13/02/2019.
//

import Metal
import simd

public class MaxEncoder {

    enum Errors: Error {
        case functionCreationFailed
        case encoderCreationFailed
        case invalidBufferStorageMode
    }

    let pipelineState: MTLComputePipelineState

    public init(library: MTLLibrary) throws {
        guard
            let function = library.makeFunction(name: MaxEncoder.functionName)
        else { throw Errors.functionCreationFailed }
        let pipelineState = try library.device.makeComputePipelineState(function: function)
        self.pipelineState = pipelineState
    }

    public func encode(inputTexture: MTLTexture,
                       blockSize: BlockSize,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) throws {
        guard
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else { throw Errors.encoderCreationFailed }

        guard resultBuffer.storageMode == .shared
        else { throw Errors.invalidBufferStorageMode }

        encoder.setTexture(inputTexture, index: 0)
        encoder.set(blockSize, at: 0)
        encoder.setBuffer(resultBuffer,
                          offset: 0,
                          index: 1)

        let threadsPerThreadgroup = self.pipelineState.max2dThreadgroupSize

        // We have to dispatch only one threadgroup so all threads can share a memory
        let threadgroupsPerGrid = MTLSize(width: 1, height: 1, depth: 1)

        encoder.setThreadgroupMemoryLength(threadsPerThreadgroup.width * threadsPerThreadgroup.height * 4 * MemoryLayout<Float16>.stride,
                                           index: 0)

        encoder.setComputePipelineState(self.pipelineState)
        encoder.dispatchThreadgroups(threadgroupsPerGrid,
                                     threadsPerThreadgroup: threadsPerThreadgroup)

        encoder.endEncoding()
    }

    public static let functionName = "max"
}
