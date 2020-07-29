import Metal

final public class YCbCrToRGBA {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: .module))
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

    public func callAsFunction(sourceYTexture: MTLTexture,
                               sourceCbCrTexture: MTLTexture,
                               destinationRGBATexture: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceYTexture: sourceYTexture,
                    sourceCbCrTexture: sourceCbCrTexture,
                    destinationRGBATexture: destinationRGBATexture,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceYTexture: MTLTexture,
                               sourceCbCrTexture: MTLTexture,
                               destinationRGBATexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceYTexture: sourceYTexture,
                    sourceCbCrTexture: sourceCbCrTexture,
                    destinationRGBATexture: destinationRGBATexture,
                    using: encoder)
    }

    public func encode(sourceYTexture: MTLTexture,
                       sourceCbCrTexture: MTLTexture,
                       destinationRGBATexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "YCbCr To RGBA"
            self.encode(sourceYTexture: sourceYTexture,
                        sourceCbCrTexture: sourceCbCrTexture,
                        destinationRGBATexture: destinationRGBATexture,
                        using: encoder)
        }
    }

    public func encode(sourceYTexture: MTLTexture,
                       sourceCbCrTexture: MTLTexture,
                       destinationRGBATexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceYTexture,
                               sourceCbCrTexture,
                               destinationRGBATexture])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationRGBATexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationRGBATexture.size)
        }
    }

    public static let functionName = "ycbcrToRGBA"
}
