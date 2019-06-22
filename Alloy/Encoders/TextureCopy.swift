//
//  TextureCopy.swift
//  Beautifier
//
//  Created by Andrey Volodin on 31/01/2019.
//

import Metal

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class TextureCopy {
    public var inputTexture: MTLTexture!
    public var outputTexture: MTLTexture!

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)
        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.pipelineState = try library.computePipelineState(function: TextureCopy.functionName,
                                                              constants: constantValues)
    }

    public func encode(using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [self.inputTexture, self.outputTexture])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: self.inputTexture!.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: self.inputTexture!.size)
        }
    }

    private static let functionName = "textureCopy"
}
