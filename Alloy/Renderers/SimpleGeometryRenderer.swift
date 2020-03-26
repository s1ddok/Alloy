//
//  SimpleGeometryRenderer.swift
//  Alloy
//
//  Created by Andrey Volodin on 15/05/2019.
//

import Metal

final public class SimpleGeometryRenderer {

    // MARK: - Properties

    private let vertexFunction: MTLFunction
    private let fragmentFunction: MTLFunction
    private var renderPipelineStates: [MTLPixelFormat: MTLRenderPipelineState] = [:]

    // MARK: - Init

    public convenience init(context: MTLContext,
                            pixelFormat: MTLPixelFormat,
                            blending: BlendingMode = .alpha) throws {
        try self.init(library: context.library(for: Self.self),
                      pixelFormat: pixelFormat,
                      blending: blending)
    }

    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat,
                blending: BlendingMode = .alpha) throws {
        guard let vertexFunction = library.makeFunction(name: Self.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: Self.fragmentFunctionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
        try self.renderPipelineState(pixelFormat: pixelFormat,
                                     blending: blending)
    }

    @discardableResult
    private func renderPipelineState(pixelFormat: MTLPixelFormat,
                                     blending: BlendingMode = .alpha) -> MTLRenderPipelineState? {
        if self.renderPipelineStates[pixelFormat] == nil {
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = self.vertexFunction
            renderPipelineDescriptor.fragmentFunction = self.fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
            renderPipelineDescriptor.colorAttachments[0].setup(blending: blending)
            renderPipelineDescriptor.depthAttachmentPixelFormat = .invalid
            renderPipelineDescriptor.stencilAttachmentPixelFormat = .invalid

            self.renderPipelineStates[pixelFormat] = try? self.vertexFunction
                                                              .device
                                                              .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }
        return self.renderPipelineStates[pixelFormat]
    }

    // MARK: - Render

    public func render(geometry: MTLBuffer,
                       type: MTLPrimitiveType = .triangle,
                       fillMode: MTLTriangleFillMode = .fill,
                       indexBuffer: MTLIndexBuffer,
                       matrix: float4x4 = float4x4(diagonal: .init(repeating: 1)),
                       color: SIMD4<Float> = .init(1, 0, 0, 1),
                       pixelFormat: MTLPixelFormat,
                       blending: BlendingMode = .alpha,
                       renderEncoder: MTLRenderCommandEncoder) {
        guard self.vertexFunction
                  .device
                  .isPixelFormatRenderingCompatible(pixelFormat: pixelFormat),
              let renderPipelineState = self.renderPipelineState(pixelFormat: pixelFormat,
                                                                 blending: blending)
        else { return }
        renderEncoder.setVertexBuffer(geometry,
                                      offset: 0,
                                      index: 0)
        renderEncoder.set(vertexValue: matrix,
                          at: 1)
        renderEncoder.set(fragmentValue: color,
                          at: 0)
        renderEncoder.setTriangleFillMode(fillMode)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.drawIndexedPrimitives(type: type,
                                            indexBuffer: indexBuffer)
    }

    public static let vertexFunctionName = "simpleVertex"
    public static let fragmentFunctionName = "plainColorFragment"
}
