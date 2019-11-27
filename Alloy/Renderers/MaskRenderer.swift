//
//  MaskRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 28/04/2019.
//

import Metal
import simd

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
public class MaskRenderer {

    public enum Errors: Error {
        case functionCreationFailed
        case libraryCreationFailed
    }

    // MARK: - Properties

    /// Mask color. Red in default.
    public var color: vector_float4 = .init(1, 0, 0, 0.3)
    /// Texture containig mask information.
    public var maskTexture: MTLTexture? = nil
    /// Rectrangle described in a normalized coodrinate system.
    public var normalizedRect: CGRect = .zero

    private let renderPipelineState: MTLRenderPipelineState

    // MARK: - Life Cycle

    /// Creates a new instance of MaskRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public convenience init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard
            let library = context.shaderLibrary(for: MaskRenderer.self)
        else { throw Errors.libraryCreationFailed }

        try self.init(library: library, pixelFormat: pixelFormat)
    }

    /// Creates a new instance of MaskRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard
            let vertexFunction = library.makeFunction(name: MaskRenderer.vertexFunctionName),
            let fragmentFunction = library.makeFunction(name: MaskRenderer.fragmentFunctionName)
        else { throw Errors.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderPipelineDescriptor.colorAttachments[0].setup(blending: .alpha)

        self.renderPipelineState = try library.device
            .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    // MARK: - Helpers

    private func constructRectangle() -> Rectangle {
        let topLeftPosition = SIMD2<Float>(Float(self.normalizedRect.minX),
                                           Float(self.normalizedRect.maxY))
        let bottomLeftPosition = SIMD2<Float>(Float(self.normalizedRect.minX),
                                              Float(self.normalizedRect.minY))
        let topRightPosition = SIMD2<Float>(Float(self.normalizedRect.maxX),
                                            Float(self.normalizedRect.maxY))
        let bottomRightPosition = SIMD2<Float>(Float(self.normalizedRect.maxX),
                                               Float(self.normalizedRect.minY))
        return Rectangle(topLeft: topLeftPosition,
                         bottomLeft: bottomLeftPosition,
                         topRight: topRightPosition,
                         bottomRight: bottomRightPosition)
    }

    // MARK: - Rendering

    /// Render a rectangle with mask in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) throws {
        // Render.
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render a rectangle with mask in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        guard self.normalizedRect != .zero else { return }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Rectangle With Mask")
        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        // Set any buffers fed into our render pipeline.
        let rectangle = self.constructRectangle()
        renderEncoder.set(vertexValue: rectangle,
                          at: 0)
        renderEncoder.setFragmentTexture(self.maskTexture,
                                         index: 0)
        renderEncoder.set(fragmentValue: self.color,
                          at: 0)
        // Draw.
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4)
        renderEncoder.popDebugGroup()
    }

    private static let vertexFunctionName = "maskVertex"
    private static let fragmentFunctionName = "maskFragment"

}
