//
//  MTLCommandBuffer+Extensions.swift
//  AIBeauty
//
//  Created by Andrey Volodin on 02/12/2018.
//

import Metal

public extension MTLCommandBuffer {
    @available(OSX 10.14, iOS 12.0, *)
    public func compute(dispatch: MTLDispatchType,
                        _ commands: (MTLComputeCommandEncoder) -> Void) {
        guard let encoder = self.makeComputeCommandEncoder(dispatchType: dispatch)
        else { return }
        
        commands(encoder)
        
        encoder.endEncoding()
    }
    
    public func compute(_ commands: (MTLComputeCommandEncoder) -> Void) {
        guard let encoder = self.makeComputeCommandEncoder()
        else { return }
        
        commands(encoder)
        
        encoder.endEncoding()
    }
    
    public func blit(_ commands: (MTLBlitCommandEncoder) -> Void) {
        guard let encoder = self.makeBlitCommandEncoder()
        else { return }
        
        commands(encoder)
        
        encoder.endEncoding()
    }
    
    public func render(descriptor: MTLRenderPassDescriptor,
                       _ commands: (MTLRenderCommandEncoder) -> Void) {
        guard let encoder = self.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }
        
        commands(encoder)
        
        encoder.endEncoding()
    }
}
