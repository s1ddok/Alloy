import MetalPerformanceShaders

public extension MPSUnaryImageKernel {
    func callAsFunction(sourceTexture: MTLTexture,
                        destinationTexture: MTLTexture,
                        in commandBuffer: MTLCommandBuffer) {
        self.encode(commandBuffer: commandBuffer,
                    sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture)
    }

    func callAsFunction(inPlaceTexture: MTLTexture,
                        fallbackCopyAllocator: MPSCopyAllocator? = nil,
                        in commandBuffer: MTLCommandBuffer) {
        var inPlaceTexture = inPlaceTexture
        self.encode(commandBuffer: commandBuffer,
                    inPlaceTexture: &inPlaceTexture,
                    fallbackCopyAllocator: fallbackCopyAllocator)
    }

}

public extension MPSNNGraph {
    func callAsFunction(inputs: [MPSImage],
                        in commandBuffer: MTLCommandBuffer) -> MPSImage? {
        return self.encode(to: commandBuffer,
                           sourceImages: inputs)
    }
}
