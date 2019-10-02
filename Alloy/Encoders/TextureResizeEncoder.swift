//
//  TextureResizeEncoder.swift
//  Adjuster
//
//  Created by Eugene Bokhan on 02.10.2019.
//

import Metal

final public class TextureResizeEncoder {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    public let samplerDescriptor: MTLSamplerDescriptor
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            minMagFilter: MTLSamplerMinMagFilter,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(context: context,
                      samplerDescriptor: samplerDescriptor,
                      scalarType: scalarType)
    }

    public convenience init(context: MTLContext,
                            samplerDescriptor: MTLSamplerDescriptor,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: library,
                      samplerDescriptor: samplerDescriptor,
                      scalarType: scalarType)
    }

    public convenience init(library: MTLLibrary,
                            minMagFilter: MTLSamplerMinMagFilter,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(library: library,
                      samplerDescriptor: samplerDescriptor,
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                samplerDescriptor: MTLSamplerDescriptor,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)

        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
        self.samplerDescriptor = samplerDescriptor
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
        encoder.set(textures: [sourceTexture, destinationTexture])

        let sampler = encoder.device.makeSamplerState(descriptor: self.samplerDescriptor)
        encoder.setSamplerState(sampler,
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
