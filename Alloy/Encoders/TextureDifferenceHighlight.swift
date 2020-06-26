import Metal

final public class TextureDifferenceHighlight {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: Bundle.module))
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

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               color: SIMD4<Float>,
                               threshold: Float,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    color: color,
                    threshold: threshold,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               color: SIMD4<Float>,
                               threshold: Float,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    color: color,
                    threshold: threshold,
                    using: encoder)
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       color: SIMD4<Float>,
                       threshold: Float,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Difference Highlight"
            self.encode(sourceTextureOne: sourceTextureOne,
                        sourceTextureTwo: sourceTextureTwo,
                        destinationTexture: destinationTexture,
                        color: color,
                        threshold: threshold,
                        using: encoder)
        }
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       color: SIMD4<Float>,
                       threshold: Float,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTextureOne,
                               sourceTextureTwo,
                               destinationTexture])
        encoder.set(color, at: 0)
        encoder.set(threshold, at: 1)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureDifferenceHighlight"
}

