//
//  PointsRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 26/04/2019.
//

import Metal
import simd

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class PointsRenderer {

    public enum Errors: Error {
        case functionCreationFailed
        case libraryCreationFailed
        case wrongRenderTargetTextureUsage
        case missingRenderTarget
    }

    // MARK: - Properties

    /// Lines described in a normalized coodrinate system to draw.
    public var points: [SimplePoint]? {
        set {
            if let newValue = newValue {
                var convertedToMetalPoints = newValue
                    .map { SimplePoint(position: packed_float2(x: -1 + ($0.position.x * 2),
                                                               y: -1 + ((1 - $0.position.y) * 2)),
                                       size: $0.size) }
                
                self.pointsBuffer = self.context.device
                    .makeBuffer(bytes: &convertedToMetalPoints,
                                length: MemoryLayout<SimplePoint>.stride * convertedToMetalPoints.count,
                                options: .storageModeShared)
            }
        }

        get {
            if let pointsBuffer = self.pointsBuffer,
                let convertedToMetalPoints = pointsBuffer
                    .array(of: SimplePoint.self,
                           count: pointsBuffer.length / MemoryLayout<SimplePoint>.stride) {
                let normalPoints = convertedToMetalPoints
                    .map { SimplePoint(position: packed_float2(x: ($0.position.x + 1) / 2,
                                                               y: 1 - (($0.position.y + 1) / 2)),
                                       size: $0.size)
                }
                return normalPoints
            } else {
                return nil
            }
        }
    }
    private var pointsBuffer: MTLBuffer?
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
            let vertexFunction = library.makeFunction(name: PointsRenderer.vertexFunctionName),
            let fragmentFunction = library.makeFunction(name: PointsRenderer.fragmentFunctionName)
        else { throw Errors.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction

        if let colorAttachmentsDescriptor = renderPipelineDescriptor.colorAttachments[0] {
            colorAttachmentsDescriptor.pixelFormat = pixelFormat

            colorAttachmentsDescriptor.isBlendingEnabled = true

            colorAttachmentsDescriptor.rgbBlendOperation = .add
            colorAttachmentsDescriptor.sourceRGBBlendFactor = .sourceAlpha
            colorAttachmentsDescriptor.destinationRGBBlendFactor = .oneMinusSourceAlpha

            colorAttachmentsDescriptor.alphaBlendOperation = .add
            colorAttachmentsDescriptor.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachmentsDescriptor.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        self.renderPipelineState = try? context.device
            .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    private static let vertexFunctionName = "pointVertex"
    private static let fragmentFunctionName = "pointFragment"

}

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
extension PointsRenderer {

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
        renderEncoder.pushDebugGroup("Draw Points Geometry")

        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        // Set any buffers fed into our render pipeline.
        renderEncoder.setVertexBuffer(self.pointsBuffer,
                                      offset: 0,
                                      index: 0)

        renderEncoder.setFragmentBytes(&self.color,
                                       length: MemoryLayout<vector_float4>.stride,
                                       index: 0)

        // Draw.
        if let pointsBuffer = self.pointsBuffer {
            let pointCount = pointsBuffer.length / MemoryLayout<SimplePoint>.stride
            renderEncoder.drawPrimitives(type: .point,
                                         vertexStart: 0,
                                         vertexCount: 1,
                                         instanceCount: pointCount)
        }

        renderEncoder.popDebugGroup()
    }

}
