import Metal

final public class TextureNormalization {

    // MARK: - Properties

    private let textureMax: TextureMax
    private let textureDivide: TextureDivideByConstant
    private let intermediateBuffer: MTLBuffer

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        try self.init(library: context.library(for: .module))
    }

    public init(library: MTLLibrary) throws {
        self.textureDivide = try .init(library: library)
        self.textureMax = try .init(library: library)
        self.intermediateBuffer = try library.device.buffer(for: SIMD4<Float>.self,
                                                            options: .storageModePrivate)
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
            encoder.label = "Texture Normalization"
            self.encode(source: source,
                        destination: destination,
                        using: encoder)
        }
    }

    public func encode(source: MTLTexture,
                       destination: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        self.textureMax(source: source,
                        result: self.intermediateBuffer,
                        using: encoder)
        self.textureDivide(source: source,
                           destination: destination,
                           constant: self.intermediateBuffer,
                           using: encoder)
    }
}
