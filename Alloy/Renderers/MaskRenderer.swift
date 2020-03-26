//
//  MaskRenderer.swift
//  Alloy
//
//  Created by Eugene Bokhan on 28/04/2019.
//

import Metal
import simd

public class MaskRenderer {

    // MARK: - Properties

    /// Mask color. Red in default.
    public var color: SIMD4<Float> = .init(1, 0, 0, 0.3)
    /// Texture containig mask information.
    public var maskTexture: MTLTexture? = nil
    /// Rectrangle described in a normalized coodrinate system.
    public var normalizedRect: CGRect = .zero

    private let vertexFunction: MTLFunction
    private let fragmentFunction: MTLFunction
    private let inversedFragmentFunction: MTLFunction
    private var renderPipelineStates: [MTLPixelFormat: [Bool: MTLRenderPipelineState]] = [:]

    // MARK: - Life Cycle

    /// Creates a new instance of MaskRenderer.
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

    /// Creates a new instance of MaskRenderer.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
    ///   - pixelFormat: Color attachment's pixel format.
    /// - Throws: Function creation error.
    public init(library: MTLLibrary,
                pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard let vertexFunction = library.makeFunction(name: Self.vertexFunctionName)
        else { throw MetalError.MTLLibraryError.functionCreationFailed }
        self.vertexFunction = vertexFunction
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(false, at: 2)
        self.fragmentFunction = try library.makeFunction(name: Self.fragmentFunctionName,
                                                         constantValues: constantValues)
        let inversedConstantValues = MTLFunctionConstantValues()
        inversedConstantValues.set(true, at: 2)
        self.inversedFragmentFunction = try library.makeFunction(name: Self.fragmentFunctionName,
                                                                 constantValues: inversedConstantValues)
        try self.renderPipelineStatePair(for: pixelFormat)
    }

    @discardableResult
    private func renderPipelineStatePair(for pixelFormat: MTLPixelFormat) -> [Bool: MTLRenderPipelineState]? {
        guard pixelFormat.isRenderable
        else { return nil }
        if self.renderPipelineStates[pixelFormat] == nil {
            let pipelineDescriptor = self.renderPipelineDescriptor(pixelFormat: pixelFormat,
                                                                   isInversed: false)
            let inversedPipelineDescriptor = self.renderPipelineDescriptor(pixelFormat: pixelFormat,
                                                                           isInversed: true)
            guard let pipelineState = try? self.vertexFunction
                                               .device
                                               .makeRenderPipelineState(descriptor: pipelineDescriptor),
                  let inversedPipelineState = try? self.vertexFunction
                                                       .device
                                                       .makeRenderPipelineState(descriptor: inversedPipelineDescriptor)
            else { return nil }
            self.renderPipelineStates[pixelFormat] = [
                false: pipelineState,
                true: inversedPipelineState
            ]
        }
        return self.renderPipelineStates[pixelFormat]
    }

    private func renderPipelineDescriptor(pixelFormat: MTLPixelFormat,
                                          isInversed: Bool) -> MTLRenderPipelineDescriptor {
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = self.vertexFunction
        renderPipelineDescriptor.fragmentFunction = isInversed
                                                  ? self.inversedFragmentFunction
                                                  : self.fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderPipelineDescriptor.colorAttachments[0].setup(blending: .alpha)
        return renderPipelineDescriptor
    }

    // MARK: - Helpers

    private func constructRectangle() -> Rectangle {
        let topLeftPosition = SIMD2<Float>(Float(self.normalizedRect.minX),
                                           Float(self.normalizedRect.maxY))
        let bottomLeftPosition = SIMD2<Float>(Float(self.normalizedRect.minX),
                                              Float(self.normalizedRect.minY))
        let topRightPosition = SIMD2<Float>(Float(self.normalizedRect.maxX),
                                            Float(self.normalizedRect.maxY))
        let bottomRightPosition = SIMD2<Float>(Float(self.normalizedRect.maxX),
                                               Float(self.normalizedRect.minY))
        return Rectangle(topLeft: topLeftPosition,
                         bottomLeft: bottomLeftPosition,
                         topRight: topRightPosition,
                         bottomRight: bottomRightPosition)
    }

    // MARK: - Rendering

    /// Render a rectangle with mask in a target texture.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: Render pass descriptor to be used.
    ///   - commandBuffer: Command buffer to put the rendering work items into.
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       isInversed: Bool,
                       commandBuffer: MTLCommandBuffer) throws {
        guard let pixelFormat = renderPassDescriptor.colorAttachments[0]
                                                    .texture?
                                                    .pixelFormat
        else { return }
        commandBuffer.render(descriptor: renderPassDescriptor, { renderEncoder in
            self.render(pixelFormat: pixelFormat,
                        isInversed: isInversed,
                        renderEncoder: renderEncoder)
        })
    }

    /// Render a rectangle with mask in a target texture.
    ///
    /// - Parameter renderEncoder: Container to put the rendering work into.
    public func render(pixelFormat: MTLPixelFormat,
                       isInversed: Bool,
                       renderEncoder: MTLRenderCommandEncoder) {
        guard self.normalizedRect != .zero,
              let renderPipelineState = self.renderPipelineStatePair(for: pixelFormat)?[isInversed]
        else { return }

        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool.
        renderEncoder.pushDebugGroup("Draw Rectangle With Mask")
        // Set render command encoder state.
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Set any buffers fed into our render pipeline.
        let rectangle = self.constructRectangle()
        renderEncoder.set(vertexValue: rectangle,
                          at: 0)
        renderEncoder.setFragmentTexture(self.maskTexture,
                                         index: 0)
        renderEncoder.set(fragmentValue: self.color,
                          at: 0)
        // Draw.
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4)
        renderEncoder.popDebugGroup()
    }

    public static let vertexFunctionName = "maskVertex"
    public static let fragmentFunctionName = "maskFragment"
}
