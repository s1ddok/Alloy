import Metal

final public class TextureNormalization {

    // MARK: - Properties

    private let textureMax: TextureMax
    private let textureDivide: TextureDivideByConstant
    private let intermediateBuffer: MTLBuffer

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: Bundle.module))
    }

    public init(library: MTLLibrary) throws {
        self.textureDivide = try .init(library: library)
        self.textureMax = try .init(library: library)
        self.intermediateBuffer = try library.device.buffer(for: SIMD4<Float>.self,
                                                            options: .storageModePrivate)
    }

    // MARK: - Encode

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    in: commandBuffer)
    }

    public func callAsFunction(sourceTexture: MTLTexture,
                               destinationTexture: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(sourceTexture: sourceTexture,
                    destinationTexture: destinationTexture,
                    using: encoder)
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Texture Normalization"
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        self.textureMax(sourceTexture: sourceTexture,
                        resultBuffer: self.intermediateBuffer,
                        using: encoder)
        self.textureDivide(sourceTexture: sourceTexture,
                           destinationTexture: destinationTexture,
                           constant: self.intermediateBuffer,
                           using: encoder)
    }
}
