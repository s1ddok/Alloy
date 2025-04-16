import Metal

public extension MTLRenderPassDescriptor {
    static func to(texture: MTLTexture,
                   loadAction: MTLRenderPassColorAttachmentDescriptor.LoadAction = .clear(.clear),
                   storeAction: MTLStoreAction = .store) -> MTLRenderPassDescriptor {
        let newDescriptor = MTLRenderPassDescriptor()
        newDescriptor.colorAttachments[0].texture = texture
        newDescriptor.colorAttachments[0].setLoadAction(loadAction)
        newDescriptor.colorAttachments[0].storeAction = storeAction
        
        return newDescriptor
    }
}
