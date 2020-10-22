import Metal

final public class TextureResize {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let samplerState: MTLSamplerState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            minMagFilter: MTLSamplerMinMagFilter) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(context: context,
                      samplerDescriptor: samplerDescriptor)
    }

    public convenience init(context: MTLContext,
                            samplerDescriptor: MTLSamplerDescriptor) throws {
        try self.init(library: context.library(for: .module),
                      samplerDescriptor: samplerDescriptor)
    }

    public convenience init(library: MTLLibrary,
                            minMagFilter: MTLSamplerMinMagFilter) throws {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.normalizedCoordinates = true
        try self.init(library: library,
                      samplerDescriptor: samplerDescriptor)
    }

    public init(library: MTLLibrary,
                samplerDescriptor: MTLSamplerDescriptor) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)

        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
        guard let samplerState = library.device
                                        .makeSamplerState(descriptor: samplerDescriptor)
        else { throw MetalError.MTLDeviceError.samplerStateCreationFailed }
        self.samplerState = samplerState
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    destination: destination,
                    in: commandBuffer)
    }

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    destination: destination,
                    using: encoder)
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Resize"
            self.encode(source: source,
                        destination: destination,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(source, destination)

        encoder.setSamplerState(self.samplerState,
                                index: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "textureResize"
}
