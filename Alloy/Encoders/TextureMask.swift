//
//  TextureMask.swift
//  Alloy
//
//  Created by Andrey Volodin on 26/04/2019.
//

import Metal

@available(iOS 11.0, tvOS 11.0, macOS 10.13, *)
public class TextureMask {
    public enum Errors: Error {
        case metalInitializationFailed
    }

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    public var inputTexture: MTLTexture? = nil
    public var maskTexture: MTLTexture? = nil
    public var outputTexture: MTLTexture? = nil

    public convenience init(context: MTLContext) throws {
        guard let library = context.shaderLibrary(for: TextureMask.self) else {
            throw Errors.metalInitializationFailed
        }

        try self.init(library: library)
    }

    public init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        self.pipelineState = try library.computePipelineState(function: TextureMask.functionName,
                                                              constants: constantValues)
    }

    public func encode(using encoder: MTLComputeCommandEncoder) {
        guard
            let input = self.inputTexture,
            let mask = self.maskTexture,
            let output = self.outputTexture
        else { return }

        encoder.set(textures: [input, mask, output])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: output.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: output.size)
        }
    }

    public static let functionName = "textureMask"
}
