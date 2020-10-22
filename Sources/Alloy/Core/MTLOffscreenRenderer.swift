import Metal

public class MTLOffscreenRenderer {

    // MARK: - Properties
    
    private var renderPassDescriptor: MTLRenderPassDescriptor
    
    public var texture: MTLTexture! {
        return self.renderPassDescriptor.colorAttachments[0].resolveTexture
            ?? self.renderPassDescriptor.colorAttachments[0].texture
    }

    // MARK: - Init
    
    public init(renderPassDescriptor: MTLRenderPassDescriptor) {
        self.renderPassDescriptor = renderPassDescriptor
    }

    // MARK: - Draw

    public func callAsFunction(in commandBuffer: MTLCommandBuffer,
                               drawCommands: (MTLRenderCommandEncoder) -> Void) {
        self.draw(in: commandBuffer,
                  drawCommands: drawCommands)
    }
    
    public func draw(in commandBuffer: MTLCommandBuffer,
                     drawCommands: (MTLRenderCommandEncoder) -> Void) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor)
        else { return }
        
        drawCommands(renderEncoder)

        renderEncoder.endEncoding()
    }
    
    public static func new(in context: MTLContext,
                           width: Int, height: Int,
                           pixelFormat: MTLPixelFormat,
                           clearColor: MTLClearColor = .clear,
                           sampleCount: Int = 1,
                           useDepthBuffer: Bool) throws -> MTLOffscreenRenderer {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        if sampleCount == 1 {
            let targetTexture = try context.texture(width: width, height: height,
                                                    pixelFormat: pixelFormat,
                                                    usage: [.shaderRead, .shaderWrite, .renderTarget])
            renderPassDescriptor.colorAttachments[0].texture = targetTexture
            renderPassDescriptor.colorAttachments[0].storeAction = .store
        } else {
            let resolvePair = try context.multisampleRenderTargetPair(width: width, height: height,
                                                                      pixelFormat: pixelFormat,
                                                                      sampleCount: sampleCount)
            renderPassDescriptor.colorAttachments[0].texture = resolvePair.main
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolvePair.resolve
            
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        }
        
        if useDepthBuffer {
            let depthBuffer = try context.depthBuffer(width: width,
                                                      height: height)
            renderPassDescriptor.depthAttachment.texture = depthBuffer
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
        } else {
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            renderPassDescriptor.depthAttachment.loadAction = .dontCare
        }
        
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .dontCare
        
        return .init(renderPassDescriptor: renderPassDescriptor)
    }
    
}
