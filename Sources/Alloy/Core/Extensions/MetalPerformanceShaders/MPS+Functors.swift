import MetalPerformanceShaders

public extension MPSUnaryImageKernel {
    func callAsFunction(source: MTLTexture,
                        destination: MTLTexture,
                        in commandBuffer: MTLCommandBuffer) {
        self.encode(commandBuffer: commandBuffer,
                    sourceTexture: source,
                    destinationTexture: destination)
    }

    func callAsFunction(inPlace: UnsafeMutablePointer<MTLTexture>,
                        fallbackCopyAllocator: MPSCopyAllocator? = nil,
                        in commandBuffer: MTLCommandBuffer) {
        self.encode(commandBuffer: commandBuffer,
                    inPlaceTexture: inPlace,
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
