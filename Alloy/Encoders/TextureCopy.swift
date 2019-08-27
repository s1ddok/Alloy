//
//  TextureCopy.swift
//  Beautifier
//
//  Created by Andrey Volodin on 31/01/2019.
//

import Metal

@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class TextureCopy {
    public enum ScalarType: String {
        case float, half, ushort, short, uint, int
    }

    public let library: MTLLibrary

    public var inputTexture: MTLTexture!
    public var outputTexture: MTLTexture!

    private let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public init(library: MTLLibrary,
                scalarType: ScalarType = .half) throws {
        self.library = library
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

        self.pipelineState = try library.computePipelineState(function: TextureCopy.functionName + "_" + scalarType.rawValue,
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
