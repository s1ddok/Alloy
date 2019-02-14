//
//  MeanEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14/02/2019.
//

import Metal
import simd

final public class MeanEncoder {

    enum Errors: Error {
        case functionCreationFailed
        case encoderCreationFailed
        case invalidBufferStorageMode
    }

    let device: MTLDevice
    let library: MTLLibrary
    let pipelineState: MTLComputePipelineState

    public init(library: MTLLibrary) throws {
        self.device = library.device
        self.library = library

        guard
            let function = library.makeFunction(name: MeanEncoder.functionName)
        else { throw Errors.functionCreationFailed }
        let pipelineState = try device.makeComputePipelineState(function: function)
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

        let threadgroupWidth = self.pipelineState.threadExecutionWidth
        let threadgroupHeight = self.pipelineState.maxTotalThreadsPerThreadgroup / threadgroupWidth
        let threadsPerThreadgroup = MTLSizeMake(threadgroupWidth, threadgroupHeight, 1)

        // We have to dispatch only one threadgroup so all threads can share a memory
        let threadgroupsPerGrid = MTLSize(width: 1, height: 1, depth: 1)

        encoder.setThreadgroupMemoryLength(threadsPerThreadgroup.width * threadsPerThreadgroup.height * 4 * MemoryLayout<Float16>.stride,
                                           index: 0)

        encoder.setComputePipelineState(self.pipelineState)
        encoder.dispatchThreadgroups(threadgroupsPerGrid,
                                     threadsPerThreadgroup: threadsPerThreadgroup)

        encoder.endEncoding()
    }

    public static let functionName = "mean"
}
