//
//  TextureCopyEncoder.swift
//  Alloy
//
//  Created by Andrey Volodin on 31/01/2019.
//

import Metal

final public class TextureCopyEncoder {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let library = context.shaderLibrary(for: type(of: self))
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: library,
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
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Copy"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        self.copy(region: sourceTexture.region,
                  from: sourceTexture,
                  to: .zero,
                  of: destinationTexture,
                  using: encoder)
    }

    public func copy(region sourceTexureRegion: MTLRegion,
                     from sourceTexture: MTLTexture,
                     to destinationTextureOrigin: MTLOrigin,
                     of destinationTexture: MTLTexture,
                     in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Copy"
            self.copy(region: sourceTexureRegion,
                      from: sourceTexture,
                      to: destinationTextureOrigin,
                      of: destinationTexture,
                      using: encoder)
        }
    }

    public func copy(region sourceTexureRegion: MTLRegion,
                     from sourceTexture: MTLTexture,
                     to destinationTextureOrigin: MTLOrigin,
                     of destinationTexture: MTLTexture,
                     using encoder: MTLComputeCommandEncoder) {
        let readOffset = SIMD2<UInt16>(x: UInt16(sourceTexureRegion.origin.x),
                                       y: UInt16(sourceTexureRegion.origin.y))
        let writeOffset = SIMD2<UInt16>(x: UInt16(destinationTextureOrigin.x),
                                        y: UInt16(destinationTextureOrigin.y))

        encoder.set(textures: [sourceTexture,
                               destinationTexture])

        encoder.set(readOffset, at: 0)
        encoder.set(writeOffset, at: 1)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: sourceTexureRegion.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: sourceTexureRegion.size)
        }
    }

    public static let functionName = "textureCopy"
}
