import Metal
#if SWIFT_PM
import ShadersSharedCode
#endif

final public class LinesRenderer {

    // MARK: - Properties

    /// Lines described in a normalized coodrinate system.
    public var lines: [Line] {
        set {
            self.linesCount = newValue.count
            self.linesBuffer = try? self.renderPipelineDescriptor
                                        .vertexFunction?
                                        .device
                                        .buffer(with: newValue,
                                                options: .storageModeShared)

        }
        get {
            if let linesBuffer = self.linesBuffer,
               let lines = linesBuffer.array(of: Line.self,
                                             count: self.linesCount) {
                return lines
            } else {
                return []
            }
        }
    }
    /// Lines color. Red in default.
    public var color: SIMD4<Float> = .init(1, 0, 0, 0)

    private var linesBuffer: MTLBuffer?
    private var linesCount: Int = 0

    private let renderPipelineDescriptor: MTLRenderPipelineDescriptor
    private var renderPipelineStates: [MTLPixelFormat: MTLRenderPipelineState] = [:]

    // MARK: - Life Cycle

    /// Creates a new instance of LinesRenderer.
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

        self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        self.renderPipelineDescriptor.vertexFunction = vertexFunction
        self.renderPipelineDescriptor.fragmentFunction = fragmentFunction
        self.renderPipelineDescriptor.colorAttachments[0].setup(blending: .alpha)

        self.renderPipelineState(for: pixelFormat)
    }

    @discardableResult
    private func renderPipelineState(for pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState? {
        guard pixelFormat.isRenderable
        else { return nil }
        if self.renderPipelineStates[pixelFormat] == nil {
            self.renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
            self.renderPipelineStates[pixelFormat] = try? self.renderPipelineDescriptor
                                                              .vertexFunction?
                                                              .device
                                                              .makeRenderPipelineState(descriptor: self.renderPipelineDescriptor)
        }
        return self.renderPipelineStates[pixelFormat]
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

    /// Render lines in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       commandBuffer: MTLCommandBuffer) {
        guard let pixelFormat = renderPassDescriptor.colorAttachments[0]
                                                    .texture?
                                                    .pixelFormat
        else { return }
        commandBuffer.render(descriptor: renderPassDescriptor) { renderEncoder in
            self.render(pixelFormat: pixelFormat,
                        renderEncoder: renderEncoder)
        }
    }

    /// Render lines in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(pixelFormat: MTLPixelFormat,
                       renderEncoder: MTLRenderCommandEncoder) {
        guard self.linesCount != 0,
              let renderPipelineState = self.renderPipelineState(for: pixelFormat)
        else { return }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Line Geometry")
        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Set any buffers fed into our render pipeline.
        renderEncoder.setVertexBuffer(self.linesBuffer,
                                      offset: 0,
                                      index: 0)
        renderEncoder.setFragmentValue(self.color, at: 0)
        // Draw.
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4,
                                     instanceCount: self.linesCount)
        renderEncoder.popDebugGroup()
    }

    public static let vertexFunctionName = "linesVertex"
    public static let fragmentFunctionName = "primitivesFragment"
}
