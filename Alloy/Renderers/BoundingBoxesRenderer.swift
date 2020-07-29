import Metal
import CoreGraphics
import ShadersSharedCode

final public class BoundingBoxesRenderer {

    // MARK: - Properties

    /// Rectrangles in a normalized coodrinate system describing bounding boxes.
    public var normalizedRects: [CGRect] = []
    /// Prefered border color of the bounding boxes. Red is default.
    public var color: SIMD4<Float> = .init(1, 0, 0, 1) {
        didSet {
            self.linesRenderer.color = self.color
        }
    }
    /// Prefered line width of the bounding boxes in pixels. 20 is default.
    public var lineWidth: Int = 20
    /// Render taregt texture size.
    ///
    /// Used for separate width calculation of vertivcal and horizontal component lines
    /// in order them to look visually equal.
    public var renderTargetSize: MTLSize = .zero

    private let linesRenderer: LinesRenderer

    // MARK: - Life Cicle

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public convenience init(context: MTLContext,
                            pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        try self.init(library: context.library(for: .module),
                      pixelFormat: pixelFormat)
    }

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.linesRenderer = try .init(library: library,
                                       pixelFormat: pixelFormat)
    }

    // MARK: - Helpers

    private func calculateBBoxComponentLines(bboxRect: CGRect) -> [Line] {
        let textureWidth = Float(self.renderTargetSize.width)
        let textureHeight = Float(self.renderTargetSize.height)
        let horizontalWidth = Float(self.lineWidth) / textureHeight
        let verticalWidth = Float(self.lineWidth) / textureWidth

        let startPoints: [SIMD2<Float>] = [.init(Float(bboxRect.minX),
                                                 Float(bboxRect.minY) - horizontalWidth / 2),
                                           .init(Float(bboxRect.minX) + verticalWidth / 2,
                                                 Float(bboxRect.maxY)),
                                           .init(Float(bboxRect.maxX),
                                                 Float(bboxRect.maxY) + horizontalWidth / 2),
                                           .init(Float(bboxRect.maxX) - verticalWidth / 2,
                                                 Float(bboxRect.minY))]
        let endPoints: [SIMD2<Float>] = [.init(Float(bboxRect.minX),
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

    public func callAsFunction(renderPassDescriptor: MTLRenderPassDescriptor,
                               commandBuffer: MTLCommandBuffer) {
        self.render(renderPassDescriptor: renderPassDescriptor,
                    commandBuffer: commandBuffer)
    }

    public func callAsFunction(pixelFormat: MTLPixelFormat,
                               renderEncoder: MTLRenderCommandEncoder) {
        self.render(pixelFormat: pixelFormat,
                    renderEncoder: renderEncoder)
    }

    /// Render bounding boxes in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) {
        guard let renderTarget = renderPassDescriptor.colorAttachments[0].texture
        else { return }
        self.renderTargetSize = renderTarget.size
        commandBuffer.render(descriptor: renderPassDescriptor) { renderEncoder in
            self.render(pixelFormat: renderTarget.pixelFormat,
                        renderEncoder: renderEncoder)
        }
    }

    /// Render bounding boxes in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(pixelFormat: MTLPixelFormat,
                       renderEncoder: MTLRenderCommandEncoder) {
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")
        // Set the lines to render.
        self.linesRenderer.lines = self.calculateBBoxesLines()
        // Render.
        self.linesRenderer.render(pixelFormat: pixelFormat,
                                  renderEncoder: renderEncoder)
        renderEncoder.popDebugGroup()
    }

}
