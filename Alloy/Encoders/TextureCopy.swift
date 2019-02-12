//
//  TextureCopy.swift
//  Beautifier
//
//  Created by Andrey Volodin on 31/01/2019.
//

import Metal

final public class TextureCopy {
    public let library: MTLLibrary

    public var inputTexture: MTLTexture!
    public var outputTexture: MTLTexture!

    private let pipelineState: MTLComputePipelineState
    private let deviceSupportsFeaturesOfGPUFamily4_v1: Bool

    public init(library: MTLLibrary) throws {
        self.library = library
        self.deviceSupportsFeaturesOfGPUFamily4_v1 = library.device.supportsFeatureSet(.iOS_GPUFamily4_v1)

        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsFeaturesOfGPUFamily4_v1
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.pipelineState = try library.computePipelineState(function: TextureCopy.functionName,
                                                              constants: constantValues)
    }

    public func encode(using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [self.inputTexture, self.outputTexture])

        if self.pipelineState.device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: self.inputTexture!.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: self.inputTexture!.size)
        }
    }

    private static let functionName = "textureCopy"
}
