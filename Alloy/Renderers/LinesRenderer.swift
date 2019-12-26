//
//  LinesRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/04/2019.
//

import Metal

final public class LinesRenderer {

    // MARK: - Properties

    /// Lines described in a normalized coodrinate system.
    public var lines: [Line] {
        set {
            var lines = newValue
            let length = MemoryLayout<Line>.stride * lines.count
            self.linesCount = lines.count
            self.linesBuffer = self.renderPipelineState
                                   .device
                                   .makeBuffer(bytes: &lines,
                                               length: length,
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
    public var color: vector_float4 = .init(1, 0, 0, 0)

    private var linesBuffer: MTLBuffer?
    private var linesCount: Int = 0

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
        guard let library = context.library(for: Self.self)
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library,
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
        guard self.linesCount != 0
        else { return }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Line Geometry")
        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        // Set any buffers fed into our render pipeline.
        renderEncoder.setVertexBuffer(self.linesBuffer,
                                      offset: 0,
                                      index: 0)
        renderEncoder.set(fragmentValue: self.color,
                          at: 0)
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
