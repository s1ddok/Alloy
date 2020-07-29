import Metal

final public class TextureMultiplyAdd {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            multiplier: Float) throws {
        try self.init(library: context.library(for: .module),
                      multiplier: multiplier)
    }

    public init(library: MTLLibrary,
                multiplier: Float) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        constantValues.set(multiplier,
                           at: 1)
        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    using: encoder)
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Multiply Add"
            self.encode(sourceTextureOne: sourceTextureOne,
                        sourceTextureTwo: sourceTextureTwo,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTextureOne,
                               sourceTextureTwo,
                               destinationTexture])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureMultiplyAdd"
}
