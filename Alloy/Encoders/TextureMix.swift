import Metal

final public class TextureMix {

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

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               maskTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    maskTexture: maskTexture,
                    destinationTexture: destinationTexture,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               maskTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    maskTexture: maskTexture,
                    destinationTexture: destinationTexture,
                    using: encoder)
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       maskTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Mix"
            self.encode(sourceTextureOne: sourceTextureOne,
                        sourceTextureTwo: sourceTextureTwo,
                        maskTexture: maskTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       maskTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTextureOne,
                               sourceTextureTwo,
                               maskTexture,
                               destinationTexture])
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureMix"
}

