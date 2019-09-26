//
//  TextureAddConstantEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 03/09/2019.
//

import Metal

final public class TextureAddConstantEncoder {

    // MARK: - Properties

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Init

    public convenience init(context: MTLContext,
                            scalarType: MTLPixelFormat.ScalarType = .half) throws {
        guard let alloyLibrary = context.shaderLibrary(for: type(of: self).self)
        else { throw CommonErrors.metalInitializationFailed }
        try self.init(library: alloyLibrary,
                      scalarType: scalarType)
    }

    public init(library: MTLLibrary,
                scalarType: MTLPixelFormat.ScalarType = .half) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)

        let constantValues = MTLFunctionConstantValues()
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)

        let functionName = type(of: self).functionName + "_" + scalarType.rawValue
        self.pipelineState = try library.computePipelineState(function: functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: float4,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { commandEncoder in
            self.encode(sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture,
                        constant: constant,
                        using: commandEncoder)
        }
    }

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       constant: float4,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [sourceTexture, destinationTexture])
        encoder.set(constant, at: 0)

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: sourceTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: sourceTexture.size)
        }
    }

    public static let functionName = "addConstant"
}

