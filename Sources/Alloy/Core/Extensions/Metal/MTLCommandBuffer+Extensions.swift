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

    // TODO: Support multisample rendering
    func render(to texture: MTLTexture,
                loadAction: MTLRenderPassColorAttachmentDescriptor.LoadAction = .clear(.clear),
                storeAction: MTLStoreAction = .store,
                _ commands: (MTLRenderCommandEncoder) -> Void) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].setLoadAction(loadAction)
        renderPassDescriptor.colorAttachments[0].storeAction = storeAction
        
        self.render(descriptor: renderPassDescriptor, commands)
    }
    
    func render(descriptor: MTLRenderPassDescriptor,
                _ commands: (MTLRenderCommandEncoder) -> Void) {
        guard let encoder = self.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        commands(encoder)
        
        encoder.endEncoding()
    }
}
