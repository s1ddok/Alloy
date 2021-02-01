import Metal

final public class Normalize {

    // MARK: - Propertires

    private let pipelineState: MTLComputePipelineState
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
    
    public func callAsFunction(source: MTLTexture,
                               mean: SIMD3<Float>,
                               std: SIMD3<Float>,
                               destination: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    mean: mean,
                    std: std,
                    destination: destination,
                    in: commandBuffer)
    }
    
    public func callAsFunction(source: MTLTexture,
                               mean: SIMD3<Float>,
                               std: SIMD3<Float>,
                               destination: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    mean: mean,
                    std: std,
                    destination: destination,
                    using: encoder)
    }


    public func encode(source: MTLTexture,
                       mean: SIMD3<Float>,
                       std: SIMD3<Float>,
                       destination: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            self.encode(source: source,
                        mean: mean,
                        std: std,
                        destination: destination,
                        using: encoder)
        }
    }
    
    public func encode(source: MTLTexture,
                       mean: SIMD3<Float>,
                       std: SIMD3<Float>,
                       destination: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(source, destination)
        encoder.setValue(mean, at: 0)
        encoder.setValue(std, at: 1)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: source.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: source.size)
        }
    }

    public static let functionName = "normalize"
}
