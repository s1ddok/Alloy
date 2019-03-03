//
//  TextureCopy.swift
//  Beautifier
//
//  Created by Andrey Volodin on 31/01/2019.
//

import Metal

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class TextureCopy {

    private let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public init(library: MTLLibrary) throws {
        #if os(iOS) || os(tvOS)
        self.deviceSupportsNonuniformThreadgroups = library.device.supportsFeatureSet(.iOS_GPUFamily4_v1)
        #elseif os(macOS)
        self.deviceSupportsNonuniformThreadgroups = library.device.supportsFeatureSet(.macOS_GPUFamily1_v3)
        #endif
        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.pipelineState = try library.computePipelineState(function: TextureCopy.functionName,
                                                              constants: constantValues)
    }

    public func encode(inputTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            encoder.set(textures: [inputTexture, outputTexture])

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.pipelineState,
                                   exactly: inputTexture.size)
            } else {
                encoder.dispatch2d(state: self.pipelineState,
                                   covering: outputTexture.size)
            }
        }
    }

    private static let functionName = "textureCopy"
}
