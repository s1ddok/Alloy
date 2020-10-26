import Metal
import MetalPerformanceShaders

final public class MaskGuidedBlur {

    // MARK: - Propertires

    public let blurRowPassState: MTLComputePipelineState
    public let blurColumnPassState: MTLComputePipelineState
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
        self.blurRowPassState = try library.computePipelineState(function: Self.blurRowPassFunctionName,
                                                                 constants: constantValues)
        self.blurColumnPassState = try library.computePipelineState(function: Self.blurColumnPassFunctionName,
                                                                    constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(source: MTLTexture,
                               mask: MTLTexture,
                               destination: MTLTexture,
                               sigma: Float,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(source: source,
                    mask: mask,
                    destination: destination,
                    sigma: sigma,
                    in: commandBuffer)
    }

    public func encode(source: MTLTexture,
                       mask: MTLTexture,
                       destination: MTLTexture,
                       sigma: Float,
                       in commandBuffer: MTLCommandBuffer) {
        let temporaryTextureDescriptor = source.descriptor
        temporaryTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        temporaryTextureDescriptor.storageMode = .private
        temporaryTextureDescriptor.pixelFormat = .rgba8Unorm

        commandBuffer.compute { encoder in
            encoder.label = "Mask Guided Blur"
            let temporaryImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                   textureDescriptor: temporaryTextureDescriptor)
            defer { temporaryImage.readCount = 0 }

            encoder.setTextures(source, mask, temporaryImage.texture)
            encoder.setValue(sigma, at: 0)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.blurRowPassState,
                                   exactly: source.size)
            } else {
                encoder.dispatch2d(state: self.blurRowPassState,
                                   covering: source.size)
            }

            encoder.setTextures(temporaryImage.texture, mask, destination)
            encoder.setValue(sigma, at: 0)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.blurColumnPassState,
                                   exactly: source.size)
            } else {
                encoder.dispatch2d(state: self.blurColumnPassState,
                                   covering: source.size)
            }
        }
    }

    public static let blurRowPassFunctionName = "maskGuidedBlurRowPass"
    public static let blurColumnPassFunctionName = "maskGuidedBlurColumnPass"
}

