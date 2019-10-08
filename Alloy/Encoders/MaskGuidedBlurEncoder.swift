//
//  MaskGuidedBlurEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 29/08/2019.
//

import Metal
import MetalPerformanceShaders

public class MaskGuidedBlurEncoder {

    public enum Errors: Error {
        case metalInitializationFailed
    }

    private let blurRowPassState: MTLComputePipelineState
    private let blurColumnPassState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public convenience init(context: MTLContext) throws {
        guard let library = context.shaderLibrary(for: type(of: self).self)
        else { throw Errors.metalInitializationFailed }

        try self.init(library: library)
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.blurRowPassState = try library.computePipelineState(function: type(of: self).blurRowPassFunctionName,
                                                                 constants: constantValues)
        self.blurColumnPassState = try library.computePipelineState(function: type(of: self).blurColumnPassFunctionName,
                                                                    constants: constantValues)
    }

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

    private static let blurRowPassFunctionName = "maskGuidedBlurRowPass"
    private static let blurColumnPassFunctionName = "maskGuidedBlurColumnPass"
}

