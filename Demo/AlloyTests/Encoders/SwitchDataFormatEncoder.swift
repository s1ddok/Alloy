//
//  SwitchDataFormatEncoder.swift
//  AlloyTests
//
//  Created by Eugene Bokhan on 03/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import Alloy

/// Switch Data Format Encoder
///
/// Convinience encoder for conversion
/// from **float** / **half** to **uint** / **ushort**
/// and backwards.
final public class SwitchDataFormatEncoder {

    // MARK: - Types

    public enum ConversionType {
        case denormalize
        case normalize
    }

    // MARK: - Propertires

    public let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool

    // MARK: - Life Cycle

    public convenience init(metalContext: MTLContext,
                            conversionType: ConversionType) throws {
        guard let alloyLibrary = metalContext.shaderLibrary(for: Self.self)
        else { throw MetalError.MTLDeviceError.libraryCreationFailed }
        try self.init(library: alloyLibrary,
                      conversionType: conversionType)
    }

    public init(library: MTLLibrary,
                conversionType: ConversionType) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supports(feature: .nonUniformThreadgroups)

        var convertFloatToUInt = conversionType == .denormalize
        var dispatchFlag = self.deviceSupportsNonuniformThreadgroups
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&dispatchFlag,
                                        type: .bool,
                                        index: 0)
        constantValues.setConstantValue(&convertFloatToUInt,
                                        type: .bool,
                                        index: 1)

        self.pipelineState = try library.computePipelineState(function: type(of: self).functionName,
                                                              constants: constantValues)
    }

    // MARK: - Encode

    public func encode(normalizedTexture: MTLTexture,
                       unnormalizedTexture: MTLTexture,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            self.encode(normalizedTexture: normalizedTexture,
                        unnormalizedTexture: unnormalizedTexture,
                        using: encoder)
        }
    }

    public func encode(normalizedTexture: MTLTexture,
                       unnormalizedTexture: MTLTexture,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.set(textures: [normalizedTexture,
                               unnormalizedTexture])

        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: normalizedTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: normalizedTexture.size)
        }
    }

    public static let functionName = "switchDataFormat"
}
