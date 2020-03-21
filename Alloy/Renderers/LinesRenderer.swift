import Metal

final public class LinesRender {

    final public class GeometryDescriptor {
        public let startPoint: SIMD2<Float>
        public let endPoint: SIMD2<Float>
        public let noramlizedWidth: Float
        public let color: SIMD4<Float>

        public init(startPoint: SIMD2<Float>,
                    endPoint: SIMD2<Float>,
                    noramlizedWidth: Float,
                    color: SIMD4<Float>) {
            self.startPoint = startPoint
            self.endPoint = endPoint
            self.noramlizedWidth = noramlizedWidth
            self.color = color
        }

        public convenience init(startPoint: CGPoint,
                                endPoint: CGPoint,
                                noramlizedWidth: CGFloat,
                                color: CGColor) {
            let startPoint = SIMD2<Float>(.init(startPoint.x),
                                          .init(startPoint.y))
            let endPoint = SIMD2<Float>(.init(endPoint.x),
                                        .init(endPoint.y))
            let noramlizedWidth = Float(noramlizedWidth)
            let ciColor = CIColor(cgColor: color)
            let color = SIMD4<Float>(.init(ciColor.red),
                                     .init(ciColor.green),
                                     .init(ciColor.blue),
                                     .init(ciColor.alpha))
            self.init(startPoint: startPoint,
                      endPoint: endPoint,
                      noramlizedWidth: noramlizedWidth,
                      color: color)
        }
    }

    // MARK: - Properties

    public var geometryDescriptors: [GeometryDescriptor] = [] {
        didSet { self.updateGeometry() }
    }
    private var lines: [Line] = []

    private let renderPipelineState: MTLRenderPipelineState

    // MARK: - Life Cycle

    /// Creates a new instance of LinesRenderer.
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

    /// Creates a new instance of LinesRenderer.
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
        renderPipelineDescriptor.colorAttachments[0].setup(blending: .alpha)

        self.renderPipelineState = try library.device
                                              .makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    private func updateGeometry() {
        self.lines = self.geometryDescriptors.map { descriptor in
            .init(startPoint: descriptor.startPoint,
                  endPoint: descriptor.endPoint,
                  width: descriptor.noramlizedWidth)
        }
    }

    // MARK: - Rendering

    /// Render lines in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) throws {
        commandBuffer.render(descriptor: renderPassDescriptor,
                             self.render(using:))
    }

    /// Render lines in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(using renderEncoder: MTLRenderCommandEncoder) {
        guard !self.lines.isEmpty
        else { return }

        #if DEBUG
        renderEncoder.pushDebugGroup("Draw Line Geometry")
        #endif
        self.lines.enumerated().forEach { index, line in
            let color = self.geometryDescriptors[index]
                            .color
            renderEncoder.setRenderPipelineState(self.renderPipelineState)
            renderEncoder.set(vertexValue: line,
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

    public static let vertexFunctionName = "linesVertex"
    public static let fragmentFunctionName = "primitivesFragment"
}
