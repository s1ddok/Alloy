import Metal

final public class TextureMask {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        try self.init(library: context.library(for: .module),
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

    public func callAsFunction(source: MTLTexture,
                               mask: MTLTexture,
                               destination: MTLTexture,
                               isInversed: Bool = false,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    mask: mask,
                    destination: destination,
                    isInversed: isInversed,
                    in: commandBuffer)
    }

    public func callAsFunction(source: MTLTexture,
                               mask: MTLTexture,
                               destination: MTLTexture,
                               isInversed: Bool = false,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    mask: mask,
                    destination: destination,
                    isInversed: isInversed,
                    using: encoder)
    }

    public func encode(source: MTLTexture,
                       mask: MTLTexture,
                       destination: MTLTexture,
                       isInversed: Bool = false,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Mask"
            self.encode(source: source,
                        mask: mask,
                        destination: destination,
                        isInversed: isInversed,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       mask: MTLTexture,
                       destination: MTLTexture,
                       isInversed: Bool = false,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(source, mask, destination)
        encoder.setValue(isInversed, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "textureMask"
}
