import Metal

final public class TextureMaskedMix {

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

    public func callAsFunction(sourceOne: MTLTexture,
                               sourceTwo: MTLTexture,
                               mask: MTLTexture,
                               destination: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceOne: sourceOne,
                    sourceTwo: sourceTwo,
                    mask: mask,
                    destination: destination,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceOne: MTLTexture,
                               sourceTwo: MTLTexture,
                               mask: MTLTexture,
                               destination: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceOne: sourceOne,
                    sourceTwo: sourceTwo,
                    mask: mask,
                    destination: destination,
                    using: encoder)
    }

    public func encode(sourceOne: MTLTexture,
                       sourceTwo: MTLTexture,
                       mask: MTLTexture,
                       destination: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Mix"
            self.encode(sourceOne: sourceOne,
                        sourceTwo: sourceTwo,
                        mask: mask,
                        destination: destination,
                        using: encoder)
        }
    }

    public func encode(sourceOne: MTLTexture,
                       sourceTwo: MTLTexture,
                       mask: MTLTexture,
                       destination: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(sourceOne, sourceTwo, mask, destination)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "textureMaskedMix"
}

