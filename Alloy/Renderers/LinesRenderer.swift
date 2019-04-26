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
    public var lines: [Line]? {
        set {
            if let newValue = newValue {
                var convertedToMetalLines = newValue
                    .map { Line(startPoint: .init(x: -1 + ($0.startPoint.x * 2),
                                                  y: -1 + ((1 - $0.startPoint.y) * 2)),
                                endPoint: .init(x: -1 + ($0.endPoint.x * 2),
                                                y: -1 + ((1 - $0.endPoint.y) * 2)),
                                width: $0.width) }
                self.linesBuffer = self.context.device
                    .makeBuffer(bytes: &convertedToMetalLines,
                                length: MemoryLayout<Line>.stride * convertedToMetalLines.count,
                                options: .storageModeShared)
            }
        }
        get {
            if let linesBuffer = self.linesBuffer,
                let convertedToMetalLines = linesBuffer
                    .array(of: Line.self,
                           count: linesBuffer.length / MemoryLayout<Line>.stride) {
                let normalLines = convertedToMetalLines
                    .map { Line(startPoint: .init(x: ($0.startPoint.x + 1) / 2,
                                                  y: 1 - (($0.startPoint.y + 1) / 2)),
                                endPoint: .init(x: ($0.endPoint.x + 1) / 2,
                                                y: 1 - (($0.endPoint.y + 1) / 2)),
                                width: $0.width) }
                return normalLines
            } else {
                return nil
            }
        }
    }
    private var linesBuffer: MTLBuffer?
    public var renderTargetAspectRatio: Float = 1
    public var color: vector_float4 = .init()

    private let context: MTLContext
    private var renderPipelineState: MTLRenderPipelineState!

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

        self.renderPipelineState = try? context.device
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
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                     commandBuffer: MTLCommandBuffer) throws {
        #if DEBUG
        // Check render target.
        guard let renderTarget = renderPassDescriptor.colorAttachments[0].texture
        else { throw Errors.missingRenderTarget }
        guard renderTarget.usage.contains(.renderTarget)
        else { throw Errors.wrongRenderTargetTextureUsage }
        #endif

        self.renderTargetAspectRatio =
            Float(renderTarget.width) / Float(renderTarget.height)

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
        renderEncoder.setVertexBuffer(self.linesBuffer,
                                      offset: 0,
                                      index: 0)

        renderEncoder.setVertexBytes(&self.renderTargetAspectRatio,
                                      length: MemoryLayout<Float>.stride,
                                      index: 1)
        renderEncoder.setFragmentBytes(&self.color,
                                       length: MemoryLayout<vector_float4>.stride,
                                       index: 0)

        // Draw.
        if let linesBuffer = self.linesBuffer {
            let linesCount = linesBuffer.length / MemoryLayout<Line>.stride
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: 4,
                                         instanceCount: linesCount)
        }

        renderEncoder.popDebugGroup()
    }

}
