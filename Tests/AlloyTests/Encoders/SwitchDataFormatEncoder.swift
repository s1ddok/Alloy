import Alloy

/// Switch Data Format Encoder
///
/// Convinience encoder for conversion
/// from **float** / **half** to **uint** / **ushort**
/// and backwards.
final public class SwitchDataFormatEncoder {

    // MARK: - Types

    public enum ConversionType {
        case denormalize
        case normalize
    }

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext,
                            conversionType: ConversionType) throws {
        try self.init(library: context.library(for: .module),
                      conversionType: conversionType)
    }

    public init(library: MTLLibrary,
                conversionType: ConversionType) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                           .supports(feature: .nonUniformThreadgroups)

        var convertFloatToUInt = conversionType == .denormalize
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)
        constantValues.setConstantValue(&convertFloatToUInt,
                                        type: .bool,
                                        index: 1)

        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func callAsFunction(normalized: MTLTexture,
                               unnormalized: MTLTexture,
                               in commandBuffer: MTLCommandBuffer) {
        self.encode(normalized: normalized,
                    unnormalized: unnormalized,
                    in: commandBuffer)
    }

    public func callAsFunction(normalized: MTLTexture,
                               unnormalized: MTLTexture,
                               using encoder: MTLComputeCommandEncoder) {
        self.encode(normalized: normalized,
                    unnormalized: unnormalized,
                    using: encoder)
    }

    public func encode(normalized: MTLTexture,
                       unnormalized: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            self.encode(normalized: normalized,
                        unnormalized: unnormalized,
                        using: encoder)
        }
    }

    public func encode(normalized: MTLTexture,
                       unnormalized: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTextures(normalized, unnormalized)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: normalized.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: normalized.size)
        }
    }

    public static let functionName = "switchDataFormat"
}
