//
//  MTLOffscreenRenderer.swift
//  Alloy
//
//  Created by Andrey Volodin on 28.10.2018.
//

import Metal

public class MTLOffscreenRenderer {
    
    fileprivate var renderPassDescriptor: MTLRenderPassDescriptor
    
    public var texture: MTLTexture! {
        return renderPassDescriptor.colorAttachments[0].resolveTexture ??
               renderPassDescriptor.colorAttachments[0].texture
    }
    
    public init(renderPassDescriptor: MTLRenderPassDescriptor) {
        self.renderPassDescriptor = renderPassDescriptor
    }
    
    public func draw(in commandBuffer: MTLCommandBuffer, drawCommands: (MTLRenderCommandEncoder) -> Void) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        drawCommands(renderEncoder)
        
        renderEncoder.endEncoding()
    }
    
    public static func new(in context: MTLContext,
                           width: Int, height: Int,
                           pixelFormat: MTLPixelFormat,
                           clearColor: MTLClearColor = .clear,
                           sampleCount: Int = 1,
                           useDepthBuffer: Bool) -> MTLOffscreenRenderer {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        if sampleCount == 1 {
            let targetTexture = context.texture(width: width, height: height,
                                                pixelFormat: pixelFormat,
                                                usage: [.shaderRead, .shaderWrite, .renderTarget])
            renderPassDescriptor.colorAttachments[0].texture = targetTexture
            renderPassDescriptor.colorAttachments[0].storeAction = .store
        } else {
            let resolvePair = context.createMultisampleRenderTargetPair(width: width, height: height,
                                                                        pixelFormat: pixelFormat,
                                                                        sampleCount: sampleCount)!
            renderPassDescriptor.colorAttachments[0].texture = resolvePair.main
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolvePair.resolve
            
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        }
        
        if useDepthBuffer {
            let depthBuffer = context.depthBuffer(width: width, height: height)
            renderPassDescriptor.depthAttachment.texture = depthBuffer
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
        } else {
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            renderPassDescriptor.depthAttachment.loadAction = .dontCare
        }
        
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .dontCare
        
        return MTLOffscreenRenderer(renderPassDescriptor: renderPassDescriptor)
    }
    
}
