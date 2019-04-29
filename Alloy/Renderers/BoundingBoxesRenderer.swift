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

    // MARK: - Properties

    /// Rectrangles in a normalized coodrinate system describing bounding boxes.
    public var normalizedRects: [CGRect] = []
    /// Prefered border color of the bounding boxes. Red is default.
    public var color: vector_float4 = .init(1, 0, 0, 1) {
        didSet {
            self.linesRenderer.color = self.color
        }
    }
    /// Prefered line width of the bounding boxes in pixels. 20 is default.
    public var lineWidth: Int = 20

    private var renderTargetSize: MTLSize = .zero
    private let linesRenderer: LinesRenderer

    // MARK: - Life Cicle

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public init(context: MTLContext, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.linesRenderer = try LinesRenderer(context: context,
                                               pixelFormat: pixelFormat)
    }

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.linesRenderer = try LinesRenderer(library: library,
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

    private func calculateBBoxesLines() -> [Line] {
        let boundingBoxesLines = (self.normalizedRects
            .map { self.calculateBBoxComponentLines(bboxRect: $0) })
            .flatMap { $0 }
        return boundingBoxesLines
    }

    // MARK: - Rendering

    /// Render bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) throws {
        self.renderTargetSize = renderPassDescriptor.colorAttachments[0].texture?.size ?? .zero
        // Render.
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render bounding boxes in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        let boundingBoxesLines = self.calculateBBoxesLines(from: self.normalizedRects)
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")
        // Set the lines to render.
        self.linesRenderer.lines = boundingBoxesLines
        // Render.
        self.linesRenderer.render(using: renderEncoder)
        renderEncoder.popDebugGroup()
    }

}
