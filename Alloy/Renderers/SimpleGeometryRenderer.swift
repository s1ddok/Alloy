//
//  SimpleGeometryRenderer.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

import Metal
import simd

public class SimpleGeometryRenderer {
    public let pipelineState: MTLRenderPipelineState

    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat,
                blending: BlendingMode = .alpha,
                label: String = "Simple Geometry Renderer") throws {
        guard
            let fragment = library.makeFunction(name: "plainColorFragment"),
            let vertex = library.makeFunction(name: "simpleVertex")
        else { throw CommonErrors.metalInitializationFailed }

        let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineStateDescriptor.label = label
        renderPipelineStateDescriptor.vertexFunction = vertex
        renderPipelineStateDescriptor.fragmentFunction = fragment
        renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderPipelineStateDescriptor.colorAttachments[0].setup(blending: blending)
        renderPipelineStateDescriptor.depthAttachmentPixelFormat = .invalid
        renderPipelineStateDescriptor.stencilAttachmentPixelFormat = .invalid

        try self.pipelineState = library.device
                                        .makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)
    }

    public func render(geometry: MTLBuffer,
                       type: MTLPrimitiveType = .triangle,
                       fillMode: MTLTriangleFillMode = .fill,
                       indexBuffer: MTLIndexBuffer,
                       matrix: float4x4 = float4x4(diagonal: .init(repeating: 1)),
                       color: SIMD4<Float> = .init(1, 0, 0, 1),
                       using encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(geometry, offset: 0, index: 0)
        encoder.set(vertexValue: matrix, at: 1)

        encoder.set(fragmentValue: color, at: 0)

        encoder.setTriangleFillMode(fillMode)
        encoder.setRenderPipelineState(self.pipelineState)
        encoder.drawIndexedPrimitives(type: type, indexBuffer: indexBuffer)
    }
}
