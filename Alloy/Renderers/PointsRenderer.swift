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

    /// Point positions described in a normalized coodrinate system.
    public var pointsPositions: [simd_float2] {
        set {
            var pointsPositions = newValue
            self.pointCount = pointsPositions.count
            self.pointsPositionsBuffer = self.context.device
                .makeBuffer(bytes: &pointsPositions,
                            length: MemoryLayout<simd_float2>.stride * pointsPositions.count,
                            options: .storageModeShared)
        }
        get {
            if let pointsPositionsBuffer = self.pointsPositionsBuffer,
                let pointsPositions = pointsPositionsBuffer
                    .array(of: simd_float2.self,
                           count: pointsPositionsBuffer.length / MemoryLayout<simd_float2>.stride) {
                return pointsPositions
            } else {
                return []
            }
        }
    }
    /// Point color. Red in default.
    public var color: vector_float4 = .init(1, 0, 0, 1)
    /// Point size in pixels
    public var pointSize: Float = 40

    private var pointsPositionsBuffer: MTLBuffer?
    private var pointCount: Int = 0

    private let context: MTLContext
    private let renderPipelineState: MTLRenderPipelineState

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
            colorAttachmentsDescriptor.setup(blending: .alpha)
        }

        self.renderPipelineState = try context.device
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
        commandBuffer.render(descriptor: renderPassDescriptor) { renderEncoder in
            self.render(using: renderEncoder)
        }

        commandBuffer.render(descriptor: renderPassDescriptor, self.render(using:))
    }

    /// Draw a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        if self.pointCount != 0 {

            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
            renderEncoder.pushDebugGroup("Draw Points Geometry")

            // Set render command encoder state.
            renderEncoder.setRenderPipelineState(self.renderPipelineState)
            // Set any buffers fed into our render pipeline.
            renderEncoder.setVertexBuffer(self.pointsBuffer,
                                          offset: 0,
                                          index: 0)
            renderEncoder.set(vertexValue: self.pointSize,
                              at: 1)

            renderEncoder.set(fragmentValue: self.color,
                              at: 0)

            // Draw.
            renderEncoder.drawPrimitives(type: .point,
                                         vertexStart: 0,
                                         vertexCount: 1,
                                         instanceCount: self.pointCount)

            renderEncoder.popDebugGroup()
        }
    }

}
