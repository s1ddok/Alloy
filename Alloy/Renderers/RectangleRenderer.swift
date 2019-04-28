//
//  RectangleRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 23/04/2019.
//

import Metal
import simd

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class RectangleRenderer {

    public enum Errors: Error {
        case functionCreationFailed
        case libraryCreationFailed
        case wrongRenderTargetTextureUsage
        case missingRenderTarget
    }

    // MARK: - Properties

    /// Rectangle fill color. Red in default.
    public var color: vector_float4 = .init(1, 0, 0, 1)
    /// Rectrangle cescribed in a normalized coodrinate system.
    public var normalizedRect: CGRect = .zero

    private let renderPipelineState: MTLRenderPipelineState

    // MARK: - Life Cycle

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public convenience init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard
            let library = context.shaderLibrary(for: RectangleRenderer.self)
        else { throw Errors.libraryCreationFailed }

        try self.init(library: library, pixelFormat: pixelFormat)
    }

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard
            let vertexFunction = library.makeFunction(name: RectangleRenderer.vertexFunctionName),
            let fragmentFunction = library.makeFunction(name: RectangleRenderer.fragmentFunctionName)
        else { throw Errors.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        self.renderPipelineState = try library.device
            .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    // MARK: - Helpers

    private func constructRectangle(from cgRect: CGRect) -> Rectangle {
        let topLeftPosition = float2(Float(cgRect.minX),
                                     Float(cgRect.maxY))
        let bottomLeftPosition = float2(Float(cgRect.minX),
                                        Float(cgRect.minY))
        let topRightPosition = float2(Float(cgRect.maxX),
                                      Float(cgRect.maxY))
        let bottomRightPosition = float2(Float(cgRect.maxX),
                                         Float(cgRect.minY))
        return Rectangle(topLeft: topLeftPosition,
                         bottomLeft: bottomLeftPosition,
                         topRight: topRightPosition,
                         bottomRight: bottomRightPosition)
    }

    // MARK: - Rendering

    /// Render a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) throws {
        #if DEBUG
        // Check render target.
        guard
            let renderTarget = renderPassDescriptor.colorAttachments[0].texture
        else { throw Errors.missingRenderTarget }
        guard
            renderTarget.usage.contains(.renderTarget)
        else { throw Errors.wrongRenderTargetTextureUsage }
        #endif

        // Render.
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        guard self.normalizedRect != .zero else { return }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Rectangle Geometry")

        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        // Set any buffers fed into our render pipeline.

        let rectangle = self.constructRectangle(from: self.normalizedRect)
        renderEncoder.set(vertexValue: rectangle,
                          at: 0)
        renderEncoder.set(fragmentValue: self.color,
                          at: 0)

        // Draw.
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4)

        renderEncoder.popDebugGroup()
    }

    private static let vertexFunctionName = "rectVertex"
    private static let fragmentFunctionName = "primitivesFragment"

}
