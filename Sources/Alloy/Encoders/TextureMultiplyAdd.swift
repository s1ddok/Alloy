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

    public func callAsFunction(sourceOne: MTLTexture,
                               sourceTwo: MTLTexture,
                               destination: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceOne: sourceOne,
                    sourceTwo: sourceTwo,
                    destination: destination,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceOne: MTLTexture,
                               sourceTwo: MTLTexture,
                               destination: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceOne: sourceOne,
                    sourceTwo: sourceTwo,
                    destination: destination,
                    using: encoder)
    }

    public func encode(sourceOne: MTLTexture,
                       sourceTwo: MTLTexture,
                       destination: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Multiply Add"
            self.encode(sourceOne: sourceOne,
                        sourceTwo: sourceTwo,
                        destination: destination,
                        using: encoder)
        }
    }

    public func encode(sourceOne: MTLTexture,
                       sourceTwo: MTLTexture,
                       destination: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(sourceOne, sourceTwo, destination)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "textureMultiplyAdd"
}
