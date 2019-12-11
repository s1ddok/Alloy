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
        if self.kernelQueue.count == 0 { return }

        let textureDescriptor = sourceTexture.descriptor
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        // We need only 2 temporary images in the worst case.
        let temporaryImagesCount = max(self.kernelQueue.count - 1, 2)
        let temporaryImages = [Int](0 ..< temporaryImagesCount).map { _ in
            MPSTemporaryImage(commandBuffer: commandBuffer,
                              textureDescriptor: textureDescriptor)
        }
        defer { temporaryImages.forEach { $0.readCount = 0 } }

        let texturesCount = self.kernelQueue.count + 1
        var textures = [Int](0 ..< texturesCount).map {
            temporaryImages[$0 % 2 == 0 ? 1 : 0].texture
        }
        textures[0] = sourceTexture
        textures[textures.count - 1] = destinationTexture

        for i in 0 ..< self.kernelQueue.count {
            let kernel = self.kernelQueue[i]
            let sourceTexture = textures[i]
            let destinationTexture = textures[i + 1]
            kernel.encode(commandBuffer: commandBuffer,
                          sourceTexture: sourceTexture,
                          destinationTexture: destinationTexture)
        }
    }
}
