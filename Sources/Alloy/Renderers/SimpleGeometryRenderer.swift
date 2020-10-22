import Metal
import simd

final public class SimpleGeometryRenderer {

    // MARK: - Properties

    private let renderPipelineDescriptor: MTLRenderPipelineDescriptor
    private var renderPipelineStates: [MTLPixelFormat: MTLRenderPipelineState] = [:]

    // MARK: - Init

    public convenience init(context: MTLContext,
                            pixelFormat: MTLPixelFormat,
                            blending: BlendingMode = .alpha) throws {
        try self.init(library: context.library(for: .module),
                      pixelFormat: pixelFormat,
                      blending: blending)
    }

    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat,
                blending: BlendingMode = .alpha) throws {
        guard let vertexFunction = library.makeFunction(name: Self.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: Self.fragmentFunctionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }

        self.renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        self.renderPipelineDescriptor.vertexFunction = vertexFunction
        self.renderPipelineDescriptor.fragmentFunction = fragmentFunction
        self.renderPipelineDescriptor.colorAttachments[0].setup(blending: blending)
        self.renderPipelineDescriptor.depthAttachmentPixelFormat = .invalid
        self.renderPipelineDescriptor.stencilAttachmentPixelFormat = .invalid

        self.renderPipelineState(pixelFormat: pixelFormat,
                                 blending: blending)
    }

    @discardableResult
    private func renderPipelineState(pixelFormat: MTLPixelFormat,
                                     blending: BlendingMode = .alpha) -> MTLRenderPipelineState? {
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

    // MARK: - Render

    public func callAsFunction(geometry: MTLBuffer,
                               type: MTLPrimitiveType = .triangle,
                               fillMode: MTLTriangleFillMode = .fill,
                               indexBuffer: MTLIndexBuffer,
                               matrix: float4x4 = float4x4(diagonal: .init(repeating: 1)),
                               color: SIMD4<Float> = .init(1, 0, 0, 1),
                               pixelFormat: MTLPixelFormat,
                               blending: BlendingMode = .alpha,
                               renderEncoder: MTLRenderCommandEncoder) {
        self.render(geometry: geometry,
                    type: type,
                    fillMode: fillMode,
                    indexBuffer: indexBuffer,
                    matrix: matrix,
                    color: color, pixelFormat: pixelFormat,
                    blending: blending,
                    renderEncoder: renderEncoder)
    }

    public func render(geometry: MTLBuffer,
                       type: MTLPrimitiveType = .triangle,
                       fillMode: MTLTriangleFillMode = .fill,
                       indexBuffer: MTLIndexBuffer,
                       matrix: float4x4 = float4x4(diagonal: .init(repeating: 1)),
                       color: SIMD4<Float> = .init(1, 0, 0, 1),
                       pixelFormat: MTLPixelFormat,
                       blending: BlendingMode = .alpha,
                       renderEncoder: MTLRenderCommandEncoder) {
        guard let renderPipelineState = self.renderPipelineState(pixelFormat: pixelFormat,
                                                                 blending: blending)
        else { return }
        renderEncoder.pushDebugGroup("Draw Simple Geometry")
        renderEncoder.setVertexBuffer(geometry,
                                      offset: 0,
                                      index: 0)
        renderEncoder.setVertexValue(matrix, at: 1)
        renderEncoder.setFragmentValue(color, at: 0)
        renderEncoder.setTriangleFillMode(fillMode)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.drawIndexedPrimitives(type: type,
                                            indexBuffer: indexBuffer)
        renderEncoder.popDebugGroup()
    }

    public static let vertexFunctionName = "simpleVertex"
    public static let fragmentFunctionName = "plainColorFragment"
}
