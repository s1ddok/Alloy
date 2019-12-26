//
//  MaskGuidedBlurEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 29/08/2019.
//

import Metal
import MetalPerformanceShaders

final public class MaskGuidedBlurEncoder {

    // MARK: - Propertires

    public let blurRowPassState: MTLComputePipelineState
    public let blurColumnPassState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: Self.self))
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        self.blurRowPassState = try library.computePipelineState(function: Self.blurRowPassFunctionName,
                                                                 constants: constantValues)
        self.blurColumnPassState = try library.computePipelineState(function: Self.blurColumnPassFunctionName,
                                                                    constants: constantValues)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       maskTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       sigma: Float,
                       in commandBuffer: MTLCommandBuffer) {
        let temporaryTextureDescriptor = sourceTexture.descriptor
        temporaryTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        temporaryTextureDescriptor.storageMode = .private
        temporaryTextureDescriptor.pixelFormat = .rgba8Unorm

        commandBuffer.compute { encoder in
            let temporaryImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                   textureDescriptor: temporaryTextureDescriptor)
            defer { temporaryImage.readCount = 0 }

            encoder.set(textures: [sourceTexture,
                                   maskTexture,
                                   temporaryImage.texture])
            encoder.set(sigma, at: 0)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.blurRowPassState,
                                   exactly: sourceTexture.size)
            } else {
                encoder.dispatch2d(state: self.blurRowPassState,
                                   covering: sourceTexture.size)
            }

            encoder.set(textures: [temporaryImage.texture,
                                   maskTexture,
                                   destinationTexture])
            encoder.set(sigma, at: 0)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.blurColumnPassState,
                                   exactly: sourceTexture.size)
            } else {
                encoder.dispatch2d(state: self.blurColumnPassState,
                                   covering: sourceTexture.size)
            }
        }
    }

    public static let blurRowPassFunctionName = "maskGuidedBlurRowPass"
    public static let blurColumnPassFunctionName = "maskGuidedBlurColumnPass"
}

