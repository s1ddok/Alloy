import Metal
import MetalPerformanceShaders

final public class RGBAToYCbCr {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    public let scale: MPSImageBilinearScale
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
        self.scale = .init(device: library.device)
    }

    // MARK: - Encode

    public func callAsFunction(sourceRGBA: MTLTexture,
                               destinationY: MTLTexture,
                               destinationCbCr: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(sourceRGBA: sourceRGBA,
                    destinationY: destinationY,
                    destinationCbCr: destinationCbCr,
                    in: commandBuffer)
    }

    public func encode(sourceRGBA: MTLTexture,
                       destinationY: MTLTexture,
                       destinationCbCr: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        if destinationCbCr.size != destinationY.size {
            let temporaryCbCrDescriptor = destinationY.descriptor
            temporaryCbCrDescriptor.pixelFormat = .rg8Unorm
            temporaryCbCrDescriptor.storageMode = .private
            let temporaryCbCr = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                  textureDescriptor: temporaryCbCrDescriptor)
            defer { temporaryCbCr.readCount = 0 }
            commandBuffer.compute { encoder in
                encoder.label = "RGBA To YCbCr"
                self.encode(sourceRGBA: sourceRGBA,
                            destinationY: destinationY,
                            destinationCbCr: temporaryCbCr.texture,
                            using: encoder)
            }
            self.scale(source: temporaryCbCr.texture,
                       destination: destinationCbCr,
                       in: commandBuffer)
        } else {
            commandBuffer.compute { encoder in
                encoder.label = "RGBA To YCbCr"
                self.encode(sourceRGBA: sourceRGBA,
                            destinationY: destinationY,
                            destinationCbCr: destinationCbCr,
                            using: encoder)
            }
        }
    }

    private func encode(sourceRGBA: MTLTexture,
                        destinationY: MTLTexture,
                        destinationCbCr: MTLTexture,
                        using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(sourceRGBA,
                            destinationY,
                            destinationCbCr)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: destinationY.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: destinationY.size)
        }
    }

    public static let functionName = "ycbcrToRGBA"
}
