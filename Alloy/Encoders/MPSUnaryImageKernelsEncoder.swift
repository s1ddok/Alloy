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
        var temporaryImages = [Int](0 ..< temporaryImagesCount).map { _ in
            MPSTemporaryImage(commandBuffer: commandBuffer,
                              textureDescriptor: textureDescriptor)
        }
        defer { temporaryImages.forEach { $0.readCount = 0 } }

        if self.kernelQueue.count == 1 {
            self.kernelQueue[0]
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture)
        } else {
            self.kernelQueue[0]
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: sourceTexture,
                        destinationTexture: temporaryImages[0].texture)
            
            for i in 1 ..< self.kernelQueue.count - 2 {
                self.kernelQueue[i]
                    .encode(commandBuffer: commandBuffer,
                            sourceTexture: temporaryImages[0].texture,
                            destinationTexture: temporaryImages[1].texture)
                
                self.swapElements(at: (0, 1),
                                  in: &temporaryImages)
            }
            
            self.kernelQueue[self.kernelQueue.count - 1]
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: temporaryImages[0].texture,
                        destinationTexture: destinationTexture)
        }
    }

    func swapElements<T>(at indices: (Int, Int),
                         in array: inout [T]) {
        let temp = array[indices.1]
        array[indices.1] = array[indices.0]
        array[indices.0] = temp
    }
}
