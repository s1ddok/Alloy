//
//  TextureResizeEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 30.09.2019.
//

import Metal

final public class TextureResizeEncoder {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let samplerState: MTLSamplerState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            minMagFilter: MTLSamplerMinMagFilter) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(context: context,
                      samplerDescriptor: samplerDescriptor)
    }

    public convenience init(context: MTLContext,
                            samplerDescriptor: MTLSamplerDescriptor) throws {
        try self.init(library: context.library(for: Self.self),
                      samplerDescriptor: samplerDescriptor)
    }

    public convenience init(library: MTLLibrary,
                            minMagFilter: MTLSamplerMinMagFilter) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(library: library,
                      samplerDescriptor: samplerDescriptor)
    }

    public init(library: MTLLibrary,
                samplerDescriptor: MTLSamplerDescriptor) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)

        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
        guard let samplerState = library.device
                                        .makeSamplerState(descriptor: samplerDescriptor)
        else { throw MetalError.MTLDeviceError.samplerStateCreationFailed }
        self.samplerState = samplerState
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Resize Encoder"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture,
                               destinationTexture])

        encoder.setSamplerState(self.samplerState,
                                index: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureResize"
}
