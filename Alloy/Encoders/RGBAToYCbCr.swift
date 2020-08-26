import Metal
import MetalPerformanceShaders

final public class RGBAToYCbCr {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            halfSizedCbCr: Bool = true) throws {
        try self.init(library: context.library(for: Self.self),
                      halfSizedCbCr: halfSizedCbCr)
    }

    public init(library: MTLLibrary,
                halfSizedCbCr: Bool = true) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        constantValues.set(halfSizedCbCr,
                           at: 2)
        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(sourceRGBA: MTLTexture,
                               destinationY: MTLTexture,
                               destinationCbCr: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceRGBA: sourceRGBA,
                    destinationY: destinationY,
                    destinationCbCr: destinationCbCr,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceRGBA: MTLTexture,
                               destinationY: MTLTexture,
                               destinationCbCr: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceRGBA: sourceRGBA,
                    destinationY: destinationY,
                    destinationCbCr: destinationCbCr,
                    using: encoder)
    }

    public func encode(sourceRGBA: MTLTexture,
                       destinationY: MTLTexture,
                       destinationCbCr: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "RGBA To YCbCr"
            self.encode(sourceRGBA: sourceRGBA,
                        destinationY: destinationY,
                        destinationCbCr: destinationCbCr,
                        using: encoder)
        }
    }

    private func encode(sourceRGBA: MTLTexture,
                        destinationY: MTLTexture,
                        destinationCbCr: MTLTexture,
                        using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(sourceRGBA,
                            destinationY,
                            destinationCbCr)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationY.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationY.size)
        }
    }

    public static let functionName = "rgbaToYCbCr"
}
