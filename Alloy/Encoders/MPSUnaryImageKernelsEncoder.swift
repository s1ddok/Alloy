//
//  MPSUnaryImageKernelsEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.09.2019.
//

import MetalPerformanceShaders

@available(iOS 11.3, *)
final public class MPSUnaryImageKernelsEncoder {

    // MARK: - Properties

    public let kernelQueue: [MPSUnaryImageKernel]

    // MARK: - Life Cycle

    public init(kernelQueue: [MPSUnaryImageKernel]) {
        self.kernelQueue = kernelQueue
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       commandBuffer: MTLCommandBuffer) {
        guard self.kernelQueue
                  .count == 0
        else { return }

        let textureDescriptor = sourceTexture.descriptor
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        // We need only 2 temporary images in the worst case.
        let temporaryImagesCount = min(self.kernelQueue.count - 1, 2)
        let temporaryImages = [Int](0 ..< temporaryImagesCount).map { _ in
            MPSTemporaryImage(commandBuffer: commandBuffer,
                              textureDescriptor: textureDescriptor)
        }
        defer { temporaryImages.forEach { $0.readCount = 0 } }

        for i in 0 ..< self.kernelQueue.count {
            let isFirstOperation = i == 0
            let isLastOperation = i == self.kernelQueue.count - 1

            let headTexture = isFirstOperation
                            ? sourceTexture
                            : temporaryImages[i % 2 == 0 ? 1 : 0].texture
            let tailTesture = isLastOperation
                            ? destinationTexture
                            : temporaryImages[i % 2 == 0 ? 0 : 1].texture

            let kernel = self.kernelQueue[i]
            kernel.encode(commandBuffer: commandBuffer,
                          sourceTexture: headTexture,
                          destinationTexture: tailTesture)
        }
    }
}
