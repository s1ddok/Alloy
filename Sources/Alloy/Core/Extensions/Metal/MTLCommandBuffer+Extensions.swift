import Metal

public extension MTLCommandBuffer {

    @available(macOS 10.15, iOS 10.3, tvOS 10.3, *)
    var gpuExecutionTime: CFTimeInterval {
        return self.gpuEndTime - self.gpuStartTime
    }

    @available(macOS 10.15, iOS 10.3, tvOS 10.3, *)
    var kernelExecutionTime: CFTimeInterval {
        return self.kernelEndTime - self.kernelStartTime
    }

    @available(OSX 10.14, iOS 12.0, *)
    func compute(dispatch: MTLDispatchType,
                 _ commands: (MTLComputeCommandEncoder) -> Void) {
        guard let encoder = self.makeComputeCommandEncoder(dispatchType: dispatch)
        else { return }

        commands(encoder)
        
        encoder.endEncoding()
    }

    func compute(_ commands: (MTLComputeCommandEncoder) -> Void) {
        guard let encoder = self.makeComputeCommandEncoder()
        else { return }

        commands(encoder)
        
        encoder.endEncoding()
    }

    func blit(_ commands: (MTLBlitCommandEncoder) -> Void) {
        guard let encoder = self.makeBlitCommandEncoder()
        else { return }

        commands(encoder)
        
        encoder.endEncoding()
    }

    func render(descriptor: MTLRenderPassDescriptor,
                _ commands: (MTLRenderCommandEncoder) -> Void) {
        guard let encoder = self.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        commands(encoder)
        
        encoder.endEncoding()
    }
}
