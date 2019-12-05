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
        let temporaryImages = [Int](0 ..< self.kernelQueue.count - 1).map { _ in
            MPSTemporaryImage(commandBuffer: commandBuffer,
                              textureDescriptor: textureDescriptor)
        }
        defer { temporaryImages.forEach { $0.readCount = 0 } }
        var textures = temporaryImages.map { $0.texture }
        textures.insert(sourceTexture, at: 0)
        textures.append(destinationTexture)

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
