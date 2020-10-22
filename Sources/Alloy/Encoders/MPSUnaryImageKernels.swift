import MetalPerformanceShaders

final public class MPSUnaryImageKernels {

    // MARK: - Properties

    public let kernelQueue: [MPSUnaryImageKernel]

    // MARK: - Life Cycle

    public init(kernelQueue: [MPSUnaryImageKernel]) {
        self.kernelQueue = kernelQueue
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    destination: destination,
                    in: commandBuffer)
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        guard !self.kernelQueue.isEmpty
        else { return }

        let textureDescriptor = source.descriptor
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
                        sourceTexture: source,
                        destinationTexture: destination)
        } else {
            self.kernelQueue[0]
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: source,
                        destinationTexture: temporaryImages[0].texture)

            for i in 1 ..< self.kernelQueue.count - 1 {
                self.kernelQueue[i]
                    .encode(commandBuffer: commandBuffer,
                            sourceTexture: temporaryImages[0].texture,
                            destinationTexture: temporaryImages[1].texture)

                temporaryImages.swapAt(0, 1)
            }

            self.kernelQueue[self.kernelQueue.count - 1]
                .encode(commandBuffer: commandBuffer,
                        sourceTexture: temporaryImages[0].texture,
                        destinationTexture: destination)
        }
    }
}
