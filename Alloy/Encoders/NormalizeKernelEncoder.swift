//
//  NormalizeKernelEncoder.swift
//  Alloy-iOS
//
//  Created by Eugene Bokhan on 08/05/2019.
//

import Metal
import simd

final public class NormalizeKernelEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw MetalErrors.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library)
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        self.pipelineState = try library.computePipelineState(function: type(of: self).functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       mean: vector_float3,
                       std: vector_float3,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Normalize Kernel"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        mean: mean,
                        std: std,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       mean: vector_float3,
                       std: vector_float3,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture, destinationTexture])
        encoder.set(mean, at: 0)
        encoder.set(std, at: 1)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "normalize"
}
