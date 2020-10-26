import Metal
import simd

final public class TextureAffineCrop {

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: .module))
    }

    public init(library: MTLLibrary) throws {
        let functionName = Self.functionName
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        constantValues.set(self.deviceSupportsNonuniformThreadgroups,
                           at: 0)
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants:  constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               affineTransform: simd_float3x3,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    destination: destination,
                    affineTransform: affineTransform,
                    in: commandBuffer)
    }

    public func callAsFunction(source: MTLTexture,
                               destination: MTLTexture,
                               affineTransform: simd_float3x3,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(source: source,
                    destination: destination,
                    affineTransform: affineTransform,
                    using: encoder)
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       affineTransform: simd_float3x3,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Affine Crop"
            self.encode(source: source,
                        destination: destination,
                        affineTransform: affineTransform,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       affineTransform: simd_float3x3,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(source, destination)
        encoder.setValue(affineTransform, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destination.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destination.size)
        }
    }

    public static let functionName = "textureAffineCrop"
}
