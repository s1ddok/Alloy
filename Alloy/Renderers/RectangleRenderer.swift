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

    // MARK: - Properties

    /// Rectangle fill color.
    public var color: CGColor = .black
    /// Rectrangle in a normalized coodrinate system to draw.
    public var normalizedRect: CGRect = .zero

    private var renderPipelineState: MTLRenderPipelineState!

    // MARK: - Life Cycle

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameter context: Alloy's Metal context.
    /// - Throws: library or function creation errors.
    public init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard
            let library = context.shaderLibrary(for: Bundle(for: RectangleRenderer.self))
        else { throw Errors.libraryCreationFailed }

        guard
            let vertexFunction = library.makeFunction(name: RectangleRenderer.vertexFunctionName),
            let fragmentFunction = library.makeFunction(name: RectangleRenderer.fragmentFunctionName)
        else { throw Errors.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        self.renderPipelineState = try? context.device
            .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    private static let vertexFunctionName = "rectVertex"
    private static let fragmentFunctionName = "rectFragment"

}

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
extension RectangleRenderer: DebugRenderer {

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: render pass descriptor to be used.
    ///   - commandBuffer: command buffer to put the rendering work items into.
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                     commandBuffer: MTLCommandBuffer) throws {
        // Check render target.
        guard let renderTarget = renderPassDescriptor.colorAttachments[0].texture
        else { throw Errors.missingRenderTarget }
        guard renderTarget.usage.contains(.renderTarget)
        else { throw Errors.wrongRenderTargetTextureUsage }

        // Draw.
        commandBuffer.render(descriptor: renderPassDescriptor) { renderEncoder in
            self.draw(using: renderEncoder)
        }
    }

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: container to put the rendering work into.
    public func draw(using renderEncoder: MTLRenderCommandEncoder) {
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Rectangle Geometry")

        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        // Set any buffers fed into our render pipeline.
        var rectVertices = normalizedRect.convertToRectVertices()
        renderEncoder.setVertexBytes(&rectVertices,
                                     length: MemoryLayout<RectVertices>.stride,
                                     index: 0)
        let colorComponents = (color.components ?? [1, 1, 1, 1]).map { Float($0) }
        var color = float4(colorComponents)
        renderEncoder.setFragmentBytes(&color,
                                       length: MemoryLayout<float4>.stride,
                                       index: 0)
        // Draw.
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4)

        renderEncoder.popDebugGroup()
    }

}

private extension CGRect {

    func convertToRectVertices() -> RectVertices {
        let topLeftVertex = Vertex(position: float2(Float(self.minX),
                                                    Float(self.maxY)))
        let bottomLeftVertex = Vertex(position: float2(Float(self.minX),
                                                       Float(self.minY)))
        let topRightVertex = Vertex(position: float2(Float(self.maxX),
                                                     Float(self.maxY)))
        let bottomRightVertex = Vertex(position: float2(Float(self.maxX),
                                                        Float(self.minY)))
        return RectVertices(topLeft: topLeftVertex,
                            bottomLeft: bottomLeftVertex,
                            topRight: topRightVertex,
                            bottomRight: bottomRightVertex)
    }

}
