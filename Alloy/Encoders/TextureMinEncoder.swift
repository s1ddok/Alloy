//
//  TextureMinEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14/02/2019.
//

import Metal

final public class TextureMinEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Min"
            self.encode(sourceTexture: sourceTexture,
                        resultBuffer: resultBuffer,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       resultBuffer: MTLBuffer,
                       using encoder: MTLComputeCommandEncoder) {
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1).clamped(to: sourceTexture.size)
        let blockSize = BlockSize(width: UInt16((sourceTexture.width + threadgroupSize.width - 1) / threadgroupSize.width),
                                  height: UInt16((sourceTexture.height + threadgroupSize.height - 1) / threadgroupSize.height))

        encoder.set(textures: [sourceTexture])
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

    public static let functionName = "textureMin"
}
