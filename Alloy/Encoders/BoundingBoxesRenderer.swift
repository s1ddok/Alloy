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
        case functionCreationFailed
        case libraryCreationFailed
    }

    private enum ComponentRectType {
        case leftRect, topRect, rightRect, bottomRect
    }

    // MARK: - Properties

    private let rectangleRenderer: RectangleRenderer
    private var renderTargetSize: MTLSize!

    // MARK: - Life Cicle

    public init(context: MTLContext) throws {
        self.rectangleRenderer = try RectangleRenderer(context: context)
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

    // MARK: - Drawing

    public func setRenderTarget(texture: MTLTexture) throws {
        self.renderTargetSize = texture.size
        try self.rectangleRenderer.setRenderTarget(texture: texture)
    }

    public func draw(rects: [CGRect],
                     of color: CGColor,
                     with lineWidth: Int,
                     using commandBuffer: MTLCommandBuffer) {
        commandBuffer.pushDebugGroup("Draw Bounding Box Geometry")

        let boundingBoxesRects = self.calculateBBoxesRects(from: rects,
                                                           with: lineWidth,
                                                           textureWidth: self.renderTargetSize.width,
                                                           textureHeight: self.renderTargetSize.height)

        boundingBoxesRects.forEach {
            self.rectangleRenderer.draw(normalizedRect: $0,
                                        of: color,
                                        using: commandBuffer)
        }

        commandBuffer.popDebugGroup()
    }
}
