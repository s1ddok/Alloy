import Metal

final public class BoundingBoxesRenderer {

    final public class BoundingBoxDescriptor {
        public let color: SIMD4<Float>
        public let normalizedLineWidth: Float
        public let normalizedRect: SIMD4<Float>
        public let labelDescriptor: LabelsRender.LabelDescriptor?

        public init(color: SIMD4<Float>,
                    normalizedLineWidth: Float,
                    normalizedRect: SIMD4<Float>,
                    labelDescriptor: LabelsRender.LabelDescriptor?) {
            self.color = color
            self.normalizedLineWidth = normalizedLineWidth
            self.normalizedRect = normalizedRect
            self.labelDescriptor = labelDescriptor
        }

        public convenience init(color: CGColor,
                                normalizedLineWidth: Float,
                                normalizedRect: CGRect,
                                labelDescriptor: LabelsRender.LabelDescriptor?) {
            let normalizedRect = SIMD4<Float>(.init(normalizedRect.origin.x),
                                              .init(normalizedRect.origin.y),
                                              .init(normalizedRect.size.width),
                                              .init(normalizedRect.size.height))
            let ciColor = CIColor(cgColor: color)
            let color = SIMD4<Float>(.init(ciColor.red),
                                     .init(ciColor.green),
                                     .init(ciColor.blue),
                                     .init(ciColor.alpha))
            self.init(color: color,
                      normalizedLineWidth: normalizedLineWidth,
                      normalizedRect: normalizedRect,
                      labelDescriptor: labelDescriptor)
        }

        public convenience init(color: CGColor,
                                normalizedLineWidth: Float,
                                normalizedRect: CGRect,
                                labelText: String?) {
            var labelDescriptor: LabelsRender.LabelDescriptor? = nil
            if let labelText = labelText {
                labelDescriptor = .init(
                    text: labelText,
                    textColor: UIColor.white.cgColor,
                    labelColor: color,
                    normalizedRect: .init(origin: .init(x: normalizedRect.origin.x,
                                                        y: normalizedRect.origin.y - 0.04),
                                          size: .init(width: normalizedRect.size.width / 2.3,
                                                      height: 0.04))
                )
            }
            self.init(color: color,
                      normalizedLineWidth: normalizedLineWidth,
                      normalizedRect: normalizedRect,
                      labelDescriptor: labelDescriptor)
        }
    }

    // MARK: - Properties

    public var descriptors: [BoundingBoxDescriptor] = [] {
        didSet {
            self.labelsRender.descriptors = self.descriptors.compactMap { $0.labelDescriptor }
            self.updateLines()
        }
    }
    public var renderTargetSize: MTLSize = .zero {
        didSet { self.labelsRender.renderTargetSize = self.renderTargetSize }
    }

    private let linesRenderer: LinesRenderer
    private let labelsRender: LabelsRender

    // MARK: - Life Cicle

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public convenience init(context: MTLContext,
                            fontAtlas: MTLFontAtlas,
                            pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        try self.init(library: context.library(for: Self.self),
                      fontAtlas: fontAtlas,
                      pixelFormat: pixelFormat)
    }

    /// Creates a new instance of BoundingBoxesRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary,
                fontAtlas: MTLFontAtlas,
                pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        self.linesRenderer = try .init(library: library,
                                       pixelFormat: pixelFormat)
        self.labelsRender = try .init(library: library,
                                      fontAtlas: fontAtlas)
    }

    // MARK: - Helpers

    private func updateLines() {
        self.linesRenderer.lines.removeAll()
        self.descriptors.forEach { descriptor in
            let textureWidth = Float(self.renderTargetSize.width)
            let textureHeight = Float(self.renderTargetSize.height)
            let horizontalWidth = descriptor.normalizedLineWidth
                                / textureHeight
                                * textureWidth
            let verticalWidth = descriptor.normalizedLineWidth

            let bboxMinX = descriptor.normalizedRect.x
            let bboxMinY = descriptor.normalizedRect.y
                         + descriptor.normalizedRect.w
            let bboxMaxX = descriptor.normalizedRect.x
                         + descriptor.normalizedRect.z
            let bboxMaxY = descriptor.normalizedRect.y

            let startPoints: [SIMD2<Float>] = [.init(bboxMinX + verticalWidth / 2,
                                                     bboxMinY),
                                               .init(bboxMinX,
                                                     bboxMaxY + horizontalWidth / 2),
                                               .init(bboxMaxX - verticalWidth / 2,
                                                     bboxMaxY),
                                               .init(bboxMaxX,
                                                     bboxMinY - horizontalWidth / 2)]
            let endPoints: [SIMD2<Float>] = [.init(bboxMinX + verticalWidth / 2,
                                                   bboxMaxY + horizontalWidth),
                                             .init(bboxMaxX - verticalWidth,
                                                   bboxMaxY + horizontalWidth / 2),
                                             .init(bboxMaxX - verticalWidth / 2,
                                                   bboxMinY - horizontalWidth),
                                             .init(bboxMinX + verticalWidth,
                                                   bboxMinY - horizontalWidth / 2)]
            let widths: [Float] = [verticalWidth,
                                   horizontalWidth,
                                   verticalWidth,
                                   horizontalWidth]

            for i in 0 ..< 4 {
                self.linesRenderer.lines.append(Line(startPoint: startPoints[i],
                                                     endPoint: endPoints[i],
                                                     width: widths[i]))
            }
            self.linesRenderer.color = descriptor.color
        }
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
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render bounding boxes in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        #if DEBUG
        renderEncoder.pushDebugGroup("Draw Bounding Box Geometry")
        #endif
        self.linesRenderer
            .render(using: renderEncoder)
        self.labelsRender
            .render(using: renderEncoder)
        #if DEBUG
        renderEncoder.popDebugGroup()
        #endif
    }

}
