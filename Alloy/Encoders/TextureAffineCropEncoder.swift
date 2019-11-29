//
//  TextureAffineCropEncoder.swift
//  Pods
//
//  Created by Andrey Volodin on 18.11.2019.
//

import Metal

final public class TextureAffineCropEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        guard let library = context.shaderLibrary(for: Self.self)
        else { throw MetalErrors.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library)
    }

    public init(library: MTLLibrary) throws {
        let functionName = Self.functionName
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants:  constantValues)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       affineTransform: simd_float3x3,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture, destinationTexture])
        encoder.set(affineTransform, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureAffineCrop"
}
