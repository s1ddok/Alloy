import Metal

final public class YCbCrToRGBA {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: Self.self))
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(sourceY: MTLTexture,
                               sourceCbCr: MTLTexture,
                               destinationRGBA: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceY: sourceY,
                    sourceCbCr: sourceCbCr,
                    destinationRGBA: destinationRGBA,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceY: MTLTexture,
                               sourceCbCr: MTLTexture,
                               destinationRGBA: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceY: sourceY,
                    sourceCbCr: sourceCbCr,
                    destinationRGBA: destinationRGBA,
                    using: encoder)
    }

    public func encode(sourceY: MTLTexture,
                       sourceCbCr: MTLTexture,
                       destinationRGBA: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "YCbCr To RGBA"
            self.encode(sourceY: sourceY,
                        sourceCbCr: sourceCbCr,
                        destinationRGBA: destinationRGBA,
                        using: encoder)
        }
    }

    public func encode(sourceY: MTLTexture,
                       sourceCbCr: MTLTexture,
                       destinationRGBA: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(sourceY, sourceCbCr, destinationRGBA)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationRGBA.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationRGBA.size)
        }
    }

    public static let functionName = "ycbcrToRGBA"
}
