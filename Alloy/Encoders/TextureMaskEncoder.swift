//
//  TextureMask.swift
//  Alloy
//
//  Created by Andrey Volodin on 26/04/2019.
//

import Metal

final public class TextureMaskEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    convenience public init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let alloyLibrary = context.shaderLibrary(for: type(of: self))
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: alloyLibrary,
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       maskTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Mask"
            self.encode(sourceTexture: sourceTexture,
                        maskTexture: maskTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       maskTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture,
                               maskTexture,
                               destinationTexture])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureMask"
}
