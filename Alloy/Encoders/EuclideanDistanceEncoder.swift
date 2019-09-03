//
//  EuclideanDistanceEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 30/08/2019.
//

import Metal

@available(iOS 11.0, tvOS 11.0, macOS 10.13, *)
final public class EuclideanDistanceEncoder {

    // MARK: - Properties

    private let pipelineState: MTLComputePipelineState

    // MARK: - Life Cycle

    convenience public init(metalContext: MTLContext,
                            scalarType: PixelFormatScalarType = .half) throws {
        guard let alloyLibrary = metalContext.shaderLibrary(for: type(of: self))
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: alloyLibrary, scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: PixelFormatScalarType = .half) throws {
        self.pipelineState = try library.computePipelineState(function: type(of: self)
                                        .functionName + "_" + scalarType.rawValue)
    }

    // MARK: - Encode

    public func encode(textureOne: MTLTexture,
                       textureTwo: MTLTexture,
                       resultBuffer: MTLBuffer,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
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
                           covering: .init(width: 1, height: 1, depth: 1),
                           threadgroupSize: threadgroupSize)
    }

    public static let functionName = "euclideanDistance"
}
