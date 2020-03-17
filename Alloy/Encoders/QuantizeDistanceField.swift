import Foundation
import Metal

final public class QuantizeDistanceField {

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
        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(inPlaceSDFTexture: MTLTexture,
                       normalizationFactor: Float,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Quantize Distance Field"
            self.encode(inPlaceSDFTexture: inPlaceSDFTexture,
                        normalizationFactor: normalizationFactor,
                        using: encoder)
        }
    }

    public func encode(inPlaceSDFTexture: MTLTexture,
                       normalizationFactor: Float,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.setTexture(inPlaceSDFTexture,
                           index: 0)
        encoder.set(normalizationFactor,
                    at: 0)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: inPlaceSDFTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: inPlaceSDFTexture.size)
        }
    }

    public static let functionName = "quantizeDistanceField"
}


