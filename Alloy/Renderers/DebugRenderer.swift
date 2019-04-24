//
//  DebugRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 24/04/2019.
//

import Metal

public protocol DebugRenderer {
    func draw(using renderEncoder: MTLRenderCommandEncoder)
    func draw(renderPassDescriptor: MTLRenderPassDescriptor,
              commandBuffer: MTLCommandBuffer) throws
}

public enum Errors: Error {
    case functionCreationFailed
    case libraryCreationFailed
    case wrongRenderTargetTextureUsage
    case missingRenderTarget
}
