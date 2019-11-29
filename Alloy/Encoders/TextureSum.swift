//
//  TextureSum.swift
//  Alloy
//
//  Created by Andrey Volodin on 08/05/2019.
//

import Metal

public class TextureSum {
    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public var inputTexture1: MTLTexture? = nil
    public var inputTexture2: MTLTexture? = nil
    public var outputTexture: MTLTexture? = nil

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device
                                                          .supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.pipelineState = try library.computePipelineState(function: Self.functionName,
                                                              constants: constantValues)
    }

    public func encode(using encoder: MTLComputeCommandEncoder) {
        guard let input1 = self.inputTexture1,
              let input2 = self.inputTexture2,
              let output = self.outputTexture
        else { return }

        encoder.set(textures: [input1,
                               input2,
                               output])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: output.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: output.size)
        }
    }

    public static let functionName = "textureSum"
}
