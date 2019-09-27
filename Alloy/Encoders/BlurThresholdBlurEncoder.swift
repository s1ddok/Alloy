//
//  BlurThresholdBlurEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.09.2019.
//

import MetalPerformanceShaders

final public class BlurThresholdBlurEncoder {

    // MARK: - Properties

    public let gaussianBlur: MPSImageGaussianBlur
    public let threshold: MPSImageThresholdBinary
    public let finalGaussianBlur: MPSImageGaussianBlur
    private let discardLastStage: Bool

    // MARK: - Life Cycle
    
    public init(device: MTLDevice,
                sigma: Float,
                gaussianBlurEdgeMode: MPSImageEdgeMode = .clamp,
                threshold: Float,
                finalSigma: Float,
                finalGaussianBlurEdgeMode: MPSImageEdgeMode = .clamp) {
        self.gaussianBlur = .init(device: device,
                                  sigma: sigma)
        self.gaussianBlur.edgeMode = gaussianBlurEdgeMode
        self.threshold = .init(device: device,
                               thresholdValue: threshold,
                               maximumValue: 1.0,
                               linearGrayColorTransform: nil)
        self.finalGaussianBlur = .init(device: device,
                                       sigma: finalSigma)
        self.finalGaussianBlur.edgeMode = finalGaussianBlurEdgeMode
        self.discardLastStage = finalSigma == 0
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       commandBuffer: MTLCommandBuffer) {
        let textureDescriptor = sourceTexture.descriptor
        textureDescriptor.storageMode = .private

        let blurredIntermediateImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                         textureDescriptor: textureDescriptor)
        defer { blurredIntermediateImage.readCount = 0 }

        if self.discardLastStage {
            self.gaussianBlur.encode(commandBuffer: commandBuffer,
                                     sourceTexture: sourceTexture,
                                     destinationTexture: blurredIntermediateImage.texture)

            self.threshold.encode(commandBuffer: commandBuffer,
                                  sourceTexture: blurredIntermediateImage.texture,
                                  destinationTexture: destinationTexture)
        } else {
            let thresholdedIntermediateImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                                 textureDescriptor: textureDescriptor)
            defer { thresholdedIntermediateImage.readCount = 0 }

            self.gaussianBlur.encode(commandBuffer: commandBuffer,
                                     sourceTexture: sourceTexture,
                                     destinationTexture: blurredIntermediateImage.texture)

            self.threshold.encode(commandBuffer: commandBuffer,
                                  sourceTexture: blurredIntermediateImage.texture,
                                  destinationTexture: thresholdedIntermediateImage.texture)

            self.finalGaussianBlur.encode(commandBuffer: commandBuffer,
                                          sourceTexture: thresholdedIntermediateImage.texture,
                                          destinationTexture: destinationTexture)
        }
    }
}
