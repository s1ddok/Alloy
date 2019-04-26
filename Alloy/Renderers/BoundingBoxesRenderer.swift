//
//  BoundingBoxesRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 22/04/2019.
//

import Metal
import simd

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class BoundingBoxesRenderer {

    public enum Errors: Error {
        case wrongRenderTargetTextureUsage
        case missingRenderTarget
    }

    // MARK: - Properties

    /// Rectrangles in a normalized coodrinate system describing bounding boxes.
    public var normalizedRects: [CGRect] = []
    /// Rrefered fill color of the bounding boxes.
    public var color: vector_float4 = .init() {
        didSet {
            self.linesRenderer.color = self.color
        }
    }
    /// Prefered line width of the bounding boxes in pixels.
    public var lineWidth: Int = 20
    /// Size of the render target texture.
    public var renderTargetSize: MTLSize = .zero

    private let linesRenderer: LinesRenderer

    // MARK: - Life Cicle

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameter context: Alloy's Metal context.
    /// - Throws: library or function creation errors.
    public init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.linesRenderer = try LinesRenderer(context: context,
                                               pixelFormat: pixelFormat)
    }

    // MARK: - Helpers

    private func calculateBBoxComponentLines(bboxRect: CGRect) -> [Line] {
        let textureWidth = Float(self.renderTargetSize.width)
        let textureHeight = Float(self.renderTargetSize.height)
        let horizontalWidth = Float(self.lineWidth) / textureHeight
        let verticalWidth = Float(self.lineWidth) / textureWidth

        let startPoints: [vector_float2] = [.init(Float(bboxRect.minX),
                                                  Float(bboxRect.minY) - horizontalWidth / 2),
                                            .init(Float(bboxRect.minX) + verticalWidth / 2,
                                                  Float(bboxRect.maxY)),
                                            .init(Float(bboxRect.maxX),
                                                  Float(bboxRect.maxY) + horizontalWidth / 2),
                                            .init(Float(bboxRect.maxX) - verticalWidth / 2,
                                                  Float(bboxRect.minY))]
        let endPoints: [vector_float2] = [.init(Float(bboxRect.minX),
                                                Float(bboxRect.maxY) + horizontalWidth / 2),
                                          .init(Float(bboxRect.maxX) - verticalWidth / 2,
                                                Float(bboxRect.maxY)),
                                          .init(Float(bboxRect.maxX),
                                                Float(bboxRect.minY) - horizontalWidth / 2),
                                          .init(Float(bboxRect.minX) + verticalWidth / 2,
                                                Float(bboxRect.minY))]
        let widths: [Float] = [Float(verticalWidth),
                               Float(horizontalWidth),
                               Float(verticalWidth),
                               Float(horizontalWidth)]

        var boundingBoxComponentLines: [Line] = []
        for i in 0 ..< 4 {
            boundingBoxComponentLines.append(Line(startPoint: startPoints[i],
                                                  endPoint: endPoints[i],
                                                  width: widths[i]))
        }
        return boundingBoxComponentLines
    }

    private func calculateBBoxesLines(from rects: [CGRect]) -> [Line] {
        let boundingBoxesLines = (rects.map {
            self.calculateBBoxComponentLines(bboxRect: $0)

        }).flatMap { $0 }
        return boundingBoxesLines
    }

}

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
extension BoundingBoxesRenderer {

    /// Draw bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: render pass descriptor to be used.
    ///   - commandBuffer: command buffer to put the GPU work items into.
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

        self.renderTargetSize = renderTarget.size

        // Draw.
        commandBuffer.render(descriptor: renderPassDescriptor,
                             render(using:))
    }

    /// Draw bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        let boundingBoxesLines = self.calculateBBoxesLines(from: self.normalizedRects)

        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")

        self.linesRenderer.lines = boundingBoxesLines
        self.linesRenderer.render(using: renderEncoder)

        renderEncoder.popDebugGroup()
    }

}
