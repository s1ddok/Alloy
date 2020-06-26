import Metal

final public class TextureInterpolation {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Init

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        try self.init(library: context.library(for: Bundle.module),
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        let functionName = Self.functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               weight: Float,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    weight: weight,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTextureOne: MTLTexture,
                               sourceTextureTwo: MTLTexture,
                               destinationTexture: MTLTexture,
                               weight: Float,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTextureOne: sourceTextureOne,
                    sourceTextureTwo: sourceTextureTwo,
                    destinationTexture: destinationTexture,
                    weight: weight,
                    using: encoder)
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       weight: Float,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Interpolation"
            self.encode(sourceTextureOne: sourceTextureOne,
                        sourceTextureTwo: sourceTextureTwo,
                        destinationTexture: destinationTexture,
                        weight: weight,
                        using: encoder)
        }
    }

    public func encode(sourceTextureOne: MTLTexture,
                       sourceTextureTwo: MTLTexture,
                       destinationTexture: MTLTexture,
                       weight: Float,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTextureOne,
                               sourceTextureTwo,
                               destinationTexture])
        encoder.set(weight, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationTexture.size)
        }
    }

    public static let functionName = "textureInterpolation"
}

