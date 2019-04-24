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
        case wrongTextureUsage
    }

    private let context: MTLContext
    private var renderPipelineDescriptor: MTLRenderPipelineDescriptor {
        didSet {
            if oldValue.colorAttachments[0].pixelFormat !=
                self.renderPipelineDescriptor.colorAttachments[0].pixelFormat {
                if let newRenderPipelineState = try? self.context.device
                    .makeRenderPipelineState(descriptor: self.renderPipelineDescriptor) {
                    self.renderPipelineState = newRenderPipelineState
                }
            }
        }
    }
    private var renderPipelineState: MTLRenderPipelineState!
    private var renderPassDescriptor: MTLRenderPassDescriptor

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameter context: Alloy's Metal context.
    /// - Throws: library or function creation errors.
    public init(context: MTLContext) throws {
        self.context = context

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
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.renderPipelineDescriptor = renderPipelineDescriptor

        self.renderPipelineState = try? self.context.device
            .makeRenderPipelineState(descriptor: self.renderPipelineDescriptor)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].clearColor = .clear
        self.renderPassDescriptor = renderPassDescriptor
    }

    /// Set MTLTexure render target.
    ///
    /// - Parameter texture: texture to render in.
    /// - Throws: Error if texture's `.usage` doesn't contain `.renderTarget`.
    public func setRenderTarget(texture: MTLTexture) throws {
        guard texture.usage.contains(.renderTarget)
        else { throw Errors.wrongTextureUsage }
        self.renderPassDescriptor.colorAttachments[0].texture = texture
        let renderPipelineDescriptor = self.renderPipelineDescriptor
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
        self.renderPipelineDescriptor = renderPipelineDescriptor
    }

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - normalizedRect: rectrangle in a normalized coodrinate system.
    ///   - color: rectangle fill color.
    ///   - commandBuffer: command buffer to put the GPU work item into.
    public func draw(normalizedRect: CGRect,
                     of color: CGColor,
                     using commandBuffer: MTLCommandBuffer) {
        if self.renderPassDescriptor.colorAttachments[0].texture != nil {
            commandBuffer.render(descriptor: self.renderPassDescriptor) { renderEncoder in
                // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
                renderEncoder.pushDebugGroup("Draw Rectangle Geometry")

                // Set render command encoder state
                renderEncoder.setRenderPipelineState(self.renderPipelineState)
                // Set any buffers fed into our render pipeline
                var rectVertices = normalizedRect.convertToRectVertices()
                renderEncoder.setVertexBytes(&rectVertices,
                                             length: MemoryLayout<RectVertices>.stride,
                                             index: 0)
                let colorComponents = (color.components ?? [1, 1, 1, 1]).map { Float($0) }
                var color = float4(colorComponents)
                renderEncoder.setFragmentBytes(&color,
                                               length: MemoryLayout<float4>.stride,
                                               index: 0)
                // Draw
                renderEncoder.drawPrimitives(type: .triangleStrip,
                                             vertexStart: 0,
                                             vertexCount: 4)

                renderEncoder.popDebugGroup()
            }
        }
    }

    private static let vertexFunctionName = "rectVertex"
    private static let fragmentFunctionName = "rectFragment"
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
