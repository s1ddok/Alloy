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

    private enum ComponentType {
        case leftLine, topLine, rightLine, bottomLine
    }

    // MARK: - Properties

    /// Rectrangles in a normalized coodrinate system describing bounding boxes.
    public var normalizedRects: [CGRect] = []
    /// Rrefered fill color of the bounding boxes.
    public var color: CGColor = .black
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

    private func calculateComponentLine(bboxRect: CGRect,
                                        lineWidth: CGFloat,
                                        textureWidth: CGFloat,
                                        textureHeight: CGFloat,
                                        for componentType: ComponentType) -> Line {
        let horizontalWidth = lineWidth / textureHeight
        let verticalWidth = lineWidth / textureWidth

        let rect = CGRect(x: -1 + bboxRect.minX * 2,
                                               y: -1 + ((1 - bboxRect.maxY) * 2),
                                               width: bboxRect.width * 2,
                                               height: bboxRect.height * 2)

        let colorComponents = (self.color.components ?? [1, 1, 1, 1]).map { Float($0) }
        let color = float4(colorComponents)

        switch componentType {
        case .leftLine:
            return Line(startPoint: vector_float2(Float(rect.minX),
                                                  Float(rect.minY - horizontalWidth / 2)),
                        endPoint: vector_float2(Float(rect.minX),
                                                Float(rect.maxY + horizontalWidth / 2)),
                        width: Float(verticalWidth),
                        fillColor: color)
        case .topLine:
            return Line(startPoint: vector_float2(Float(rect.minX + verticalWidth / 2),
                                                  Float(rect.maxY)),
                        endPoint: vector_float2(Float(rect.maxX - verticalWidth / 2),
                                                Float(rect.maxY)),
                        width: Float(horizontalWidth),
                        fillColor: color)
        case .rightLine:
            return Line(startPoint: vector_float2(Float(rect.maxX),
                                                  Float(rect.maxY + horizontalWidth / 2)),
                        endPoint: vector_float2(Float(rect.maxX),
                                                Float(rect.minY - horizontalWidth / 2)),
                        width: Float(verticalWidth),
                        fillColor: color)
        case .bottomLine:
            return Line(startPoint: vector_float2(Float(rect.maxX - verticalWidth / 2),
                                                  Float(rect.minY)),
                        endPoint: vector_float2(Float(rect.minX + verticalWidth / 2),
                                                Float(rect.minY)),
                        width: Float(horizontalWidth),
                        fillColor: color)
        }
    }

    private func calculateBBoxComponentLines(bboxRect: CGRect,
                                             lineWidth: CGFloat,
                                             textureWidth: CGFloat,
                                             textureHeight: CGFloat) -> [Line] {
        let boundingBoxComponents: [ComponentType] = [.leftLine,
                                                      .topLine,
                                                      .rightLine,
                                                      .bottomLine]
        let boundingBoxComponentLines: [Line] = boundingBoxComponents.map { componentType in
            self.calculateComponentLine(bboxRect: bboxRect,
                                        lineWidth: lineWidth,
                                        textureWidth: textureWidth,
                                        textureHeight: textureHeight,
                                        for: componentType)
        }
        return boundingBoxComponentLines
    }

    private func calculateBBoxesLines(from rects: [CGRect],
                                      with lineWidth: Int,
                                      textureWidth: Int,
                                      textureHeight: Int) -> [Line] {
        let boundingBoxesLines = (rects.map {
            self.calculateBBoxComponentLines(bboxRect: $0,
                                             lineWidth: CGFloat(lineWidth),
                                             textureWidth: CGFloat(textureWidth),
                                             textureHeight: CGFloat(textureHeight))

        }).flatMap { $0 }
        return boundingBoxesLines
    }

}

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
extension BoundingBoxesRenderer: DebugRenderer {

    /// Draw bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: render pass descriptor to be used.
    ///   - commandBuffer: command buffer to put the GPU work items into.
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                     commandBuffer: MTLCommandBuffer) throws {
        // Check render target.
        guard let renderTarget = renderPassDescriptor.colorAttachments[0].texture
        else { throw Errors.missingRenderTarget }
        guard renderTarget.usage.contains(.renderTarget)
        else { throw Errors.wrongRenderTargetTextureUsage }

        self.renderTargetSize = renderTarget.size

        // Draw.
        commandBuffer.render(descriptor: renderPassDescriptor) { renderEncoder in
            self.draw(using: renderEncoder)
        }
    }

    /// Draw bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderEncoder: container to put the rendering work into.
    public func draw(using renderEncoder: MTLRenderCommandEncoder) {
        let boundingBoxesLines = self.calculateBBoxesLines(from: self.normalizedRects,
                                                           with: self.lineWidth,
                                                           textureWidth: self.renderTargetSize.width,
                                                           textureHeight: self.renderTargetSize.height)

        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")

        self.linesRenderer.lines = boundingBoxesLines
        self.linesRenderer.draw(using: renderEncoder)

        renderEncoder.popDebugGroup()
    }

}
