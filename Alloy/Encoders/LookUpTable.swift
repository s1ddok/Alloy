//
//  LookUpTable.swift
//  Alloy
//
//  Created by Andrey Volodin on 29.10.2019.
//

import Metal

final public class LookUpTable {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        guard let library = context.library(for: Self.self)
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: library)
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

    public func encode(sourceTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       lut: MTLTexture,
                       intensity: Float,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.label = "Look Up Table"
            self.encode(sourceTexture: sourceTexture,
                        outputTexture: outputTexture,
                        lut: lut,
                        intensity: intensity,
                        using: encoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       lut: MTLTexture,
                       intensity: Float,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture,
                               outputTexture,
                               lut])
        encoder.set(intensity, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: pipelineState,
                               exactly: outputTexture.size)
        } else {
            encoder.dispatch2d(state: pipelineState,
                               covering: outputTexture.size)
        }
    }

    public static let functionName = "lookUpTable"
}
