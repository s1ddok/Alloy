//
//  NormalizeKernelEncoder.swift
//  Alloy-iOS
//
//  Created by Eugene Bokhan on 08/05/2019.
//

import Metal
import simd

@available(iOS 11.0, macOS 10.13, *)
final public class NormalizeKernelEncoder {

    // MARK: - Errors

    internal enum Errors: Error {
        case libraryCreationFailed
    }

    // MARK: - Propertires

    private let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(context: MTLContext) throws {
        guard
            let library = context.shaderLibrary(for: NormalizeKernelEncoder.self)
        else { throw Errors.libraryCreationFailed }
        
        try self.init(library: library)
    }

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

        self.pipelineState = try library.computePipelineState(function: NormalizeKernelEncoder.functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(inputTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       mean: vector_float3,
                       std: vector_float3,
                       in commandBuffer: MTLCommandBuffer) throws {
        commandBuffer.compute { encoder in
            encoder.pushDebugGroup("Normalize Kernel Encoder")
            encoder.setTextures([inputTexture, outputTexture],
                                range: 0 ..< 2)
            encoder.set(mean, at: 0)
            encoder.set(std, at: 1)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatch2d(state: self.pipelineState,
                                   exactly: inputTexture.size)
            } else {
                encoder.dispatch2d(state: self.pipelineState,
                                   covering: inputTexture.size)
            }
            encoder.popDebugGroup()
        }
    }

    private static let functionName = "normalize"
}
