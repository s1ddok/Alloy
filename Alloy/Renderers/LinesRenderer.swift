//
//  LinesRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/04/2019.
//

import Metal
import simd

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class LinesRenderer {

    public enum Errors: Error {
        case functionCreationFailed
        case libraryCreationFailed
        case wrongRenderTargetTextureUsage
        case missingRenderTarget
    }

    // MARK: - Properties

    /// Lines described in a normalized coodrinate system to draw.
    public var lines: [Line] {
        set {
            var lines = newValue
            self.linesCount = lines.count
            self.linesBuffer = self.context.device
                .makeBuffer(bytes: &lines,
                            length: MemoryLayout<Line>.stride * lines.count,
                            options: .storageModeShared)
        }
        get {
            if let linesBuffer = self.linesBuffer,
                let lines = linesBuffer
                    .array(of: Line.self,
                           count: linesBuffer.length / MemoryLayout<Line>.stride) {
                return lines
            } else {
                return []
            }
        }
    }
    public var color: vector_float4 = .init(1, 0, 0, 0) // red

    private let context: MTLContext
    private let renderPipelineState: MTLRenderPipelineState
    private var linesBuffer: MTLBuffer?
    private var linesCount: Int = 0

    // MARK: - Life Cycle

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameter context: Alloy's Metal context.
    /// - Throws: library or function creation errors.
    public init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.context = context

        guard
            let library = context.shaderLibrary(for: Bundle(for: RectangleRenderer.self))
        else { throw Errors.libraryCreationFailed }

        guard
            let vertexFunction = library.makeFunction(name: LinesRenderer.vertexFunctionName),
            let fragmentFunction = library.makeFunction(name: LinesRenderer.fragmentFunctionName)
        else { throw Errors.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        self.renderPipelineState = try context.device
            .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    private static let vertexFunctionName = "linesVertex"
    private static let fragmentFunctionName = "primitivesFragment"

}

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
extension LinesRenderer {

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: render pass descriptor to be used.
    ///   - commandBuffer: command buffer to put the rendering work items into.
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

        // Draw.
        commandBuffer.render(descriptor: renderPassDescriptor,
                             render(using:))
    }

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        if self.linesCount != 0 {
            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
            renderEncoder.pushDebugGroup("Draw Rectangle Geometry")

            // Set render command encoder state.
            renderEncoder.setRenderPipelineState(self.renderPipelineState)
            // Set any buffers fed into our render pipeline.
            renderEncoder.setVertexBuffer(self.linesBuffer,
                                          offset: 0,
                                          index: 0)
            renderEncoder.set(fragmentValue: self.color,
                              at: 0)

            // Draw.
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: 4,
                                         instanceCount: self.linesCount)

            renderEncoder.popDebugGroup()
        }
    }

}
