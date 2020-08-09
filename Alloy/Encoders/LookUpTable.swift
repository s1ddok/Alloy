import Metal

final public class LookUpTable {

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
        let functionName = Self.functionName
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               lut: MTLTexture,
                               intensity: Float,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    destination: destination,
                    lut: lut,
                    intensity: intensity,
                    in: commandBuffer)
    }

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               lut: MTLTexture,
                               intensity: Float,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    destination: destination,
                    lut: lut,
                    intensity: intensity,
                    using: encoder)
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       lut: MTLTexture,
                       intensity: Float,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Look Up Table"
            self.encode(source: source,
                        destination: destination,
                        lut: lut,
                        intensity: intensity,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       lut: MTLTexture,
                       intensity: Float,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(source, destination, lut)
        encoder.setValue(intensity, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "lookUpTable"
}
