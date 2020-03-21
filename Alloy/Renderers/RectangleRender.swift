import Metal

final public class RectangleRender {

    final public class GeometryDescriptor {
        public let color: SIMD4<Float>
        public let normalizedRect: SIMD4<Float>

        public init(color: SIMD4<Float>,
                    normalizedRect: SIMD4<Float>) {
            self.color = color
            self.normalizedRect = normalizedRect
        }

        public convenience init(color: CGColor,
                                normalizedRect: CGRect) {
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
                      normalizedRect: normalizedRect)
        }
    }

    // MARK: - Properties

    public var geometryDescriptors: [GeometryDescriptor] = [] {
        didSet { self.updateGeometry() }
    }
    private var rectangles: [Rectangle] = []
    private let renderPipelineState: MTLRenderPipelineState

    // MARK: - Life Cycle

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Library or function creation errors.
    public convenience init(context: MTLContext,
                            pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        try self.init(library: context.library(for: Self.self),
                      pixelFormat: pixelFormat)
    }

    /// Creates a new instance of RectangleRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard let vertexFunction = library.makeFunction(name: Self.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: Self.fragmentFunctionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        self.renderPipelineState = try library.device
                                              .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    // MARK: - Helpers

    private func updateGeometry() {
        self.rectangles
            .removeAll()
        self.geometryDescriptors
            .forEach { descriptor in
            let originX = descriptor.normalizedRect.x
            let originY = descriptor.normalizedRect.y
            let width = descriptor.normalizedRect.z
            let height = descriptor.normalizedRect.w
            let topLeftPosition = SIMD2<Float>(originX, originY)
            let bottomLeftPosition = SIMD2<Float>(originX, originY + height)
            let topRightPosition = SIMD2<Float>(originX + width, originY)
            let bottomRightPosition = SIMD2<Float>(originX + width, originY + height)
            let rect = Rectangle(topLeft: topLeftPosition,
                                 bottomLeft: bottomLeftPosition,
                                 topRight: topRightPosition,
                                 bottomRight: bottomRightPosition)
            self.rectangles.append(rect)
        }
    }

    // MARK: - Rendering

    /// Render a rectangle in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) throws {
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render a rectangle in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        guard !self.rectangles.isEmpty
        else { return }

        #if DEBUG
        renderEncoder.pushDebugGroup("Draw Rectangle Geometry")
        #endif
        self.rectangles.enumerated().forEach { index, rectangle in
            let rectangle = self.rectangles[index]
            let color = self.geometryDescriptors[index].color

            renderEncoder.setRenderPipelineState(self.renderPipelineState)
            renderEncoder.set(vertexValue: rectangle,
                              at: 0)
            renderEncoder.set(fragmentValue: color,
                              at: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: 4)
        }
        #if DEBUG
        renderEncoder.popDebugGroup()
        #endif
    }

    public static let vertexFunctionName = "rectVertex"
    public static let fragmentFunctionName = "primitivesFragment"
}
