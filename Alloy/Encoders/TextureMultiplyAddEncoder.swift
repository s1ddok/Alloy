//
//  TextureMultiplyAddEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14.11.2019.
//

import Metal

final public class TextureMultiplyAddEncoder {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool
    public let multiplier: Float

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            multiplier: Float,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: library,
                      multiplier: multiplier,
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                multiplier: Float,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
        self.multiplier = multiplier
    }

    // MARK: - Encode

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Multiply Add"
            self.encode(sourceTextureOne: sourceTextureOne,
                        sourceTextureTwo: sourceTextureTwo,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTextureOne,
                               sourceTextureTwo,
                               destinationTexture])
        encoder.set(self.multiplier, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureMultiplyAdd"
}
