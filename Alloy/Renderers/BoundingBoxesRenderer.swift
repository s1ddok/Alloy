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

    private enum ComponentRectType {
        case leftRect, topRect, rightRect, bottomRect
    }

    // MARK: - Properties

    /// Rectrangles in a normalized coodrinate system describing bounding boxes.
    public var normalizedRects: [CGRect] = []
    /// Rrefered fill color of the bounding boxes.
    public var color: CGColor = .black {
        didSet {
            self.rectangleRenderer.color = self.color
        }
    }
    /// Prefered line width of the bounding boxes in pixels.
    public var lineWidth: Int = 20

    /// Size of the render target texture.
    public var renderTargetSize: MTLSize = .zero

    private let rectangleRenderer: RectangleRenderer

    // MARK: - Life Cicle

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameter context: Alloy's Metal context.
    /// - Throws: library or function creation errors.
    public init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.rectangleRenderer = try RectangleRenderer(context: context,
                                                       pixelFormat: pixelFormat)
    }

    // MARK: - Helpers

    private func calculateComponentRect(bboxRect: CGRect,
                                        lineWidth: CGFloat,
                                        textureWidth: CGFloat,
                                        textureHeight: CGFloat,
                                        for componentRectType: ComponentRectType) -> CGRect {
        let normalizedLineHorizontalWidth = lineWidth / textureHeight
        let normalizedLineVerticalWidth = lineWidth / textureWidth

        let normalizedToMetalBBoxRect = CGRect(x: -1 + bboxRect.minX * 2,
                                               y: -1 + ((1 - bboxRect.maxY) * 2),
                                               width: bboxRect.width * 2,
                                               height: bboxRect.height * 2)

        switch componentRectType {
        case .leftRect:
            return CGRect(x: normalizedToMetalBBoxRect.minX - normalizedLineVerticalWidth / 2,
                          y: normalizedToMetalBBoxRect.minY + normalizedLineHorizontalWidth / 2,
                          width: normalizedLineVerticalWidth,
                          height: normalizedToMetalBBoxRect.height + normalizedLineHorizontalWidth)
        case .topRect:
            return CGRect(x: normalizedToMetalBBoxRect.minX + normalizedLineVerticalWidth / 2,
                          y: normalizedToMetalBBoxRect.maxY + normalizedLineHorizontalWidth / 2,
                          width: normalizedToMetalBBoxRect.width - normalizedLineVerticalWidth,
                          height: normalizedLineHorizontalWidth)
        case .rightRect:
            return CGRect(x: normalizedToMetalBBoxRect.maxX - normalizedLineVerticalWidth / 2,
                          y: normalizedToMetalBBoxRect.minY + normalizedLineHorizontalWidth / 2,
                          width: normalizedLineVerticalWidth,
                          height: normalizedToMetalBBoxRect.height + normalizedLineHorizontalWidth)
        case .bottomRect:
            return CGRect(x: normalizedToMetalBBoxRect.minX + normalizedLineVerticalWidth / 2,
                          y: normalizedToMetalBBoxRect.minY + normalizedLineHorizontalWidth / 2,
                          width: normalizedToMetalBBoxRect.width - normalizedLineVerticalWidth,
                          height: normalizedLineHorizontalWidth)
        }
    }

    private func calculateBBoxComponentRects(bboxRect: CGRect,
                                             lineWidth: CGFloat,
                                             textureWidth: CGFloat,
                                             textureHeight: CGFloat) -> [CGRect] {
        let boundingBoxComponents: [ComponentRectType] = [.leftRect,
                                                          .topRect,
                                                          .rightRect,
                                                          .bottomRect]
        let boundingBoxComponentRects: [CGRect] = boundingBoxComponents.map { componentRectType in
            self.calculateComponentRect(bboxRect: bboxRect,
                                        lineWidth: lineWidth,
                                        textureWidth: textureWidth,
                                        textureHeight: textureHeight,
                                        for: componentRectType)
        }
        return boundingBoxComponentRects
    }

    private func calculateBBoxesRects(from rects: [CGRect],
                                      with lineWidth: Int,
                                      textureWidth: Int,
                                      textureHeight: Int) -> [CGRect] {
        let boundingBoxesRects = (rects.map {
            self.calculateBBoxComponentRects(bboxRect: $0,
                                             lineWidth: CGFloat(lineWidth),
                                             textureWidth: CGFloat(textureWidth),
                                             textureHeight: CGFloat(textureHeight))

        }).flatMap { $0 }
        return boundingBoxesRects
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
        let boundingBoxesRects = self.calculateBBoxesRects(from: self.normalizedRects,
                                                           with: self.lineWidth,
                                                           textureWidth: self.renderTargetSize.width,
                                                           textureHeight: self.renderTargetSize.height)

        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")

        boundingBoxesRects.forEach { boundingBoxComponent in
            self.rectangleRenderer.normalizedRect = boundingBoxComponent
            self.rectangleRenderer.draw(using: renderEncoder)
        }

        renderEncoder.popDebugGroup()
    }

}
