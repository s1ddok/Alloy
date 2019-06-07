//
//  TextureCropEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 07/06/2019.
//

import Metal


/// Texture Crop Encoder
@available(iOS 11.3, tvOS 11.3, macOS 10.13, *)
final public class TextureCropEncoder {
    
    public enum Errors: Error {
        case libraryCreationFailed
    }
    
    // MARK: - Properties
    
    private let pipelineState: MTLComputePipelineState
    private let deviceSupportsNonuniformThreadgroups: Bool
    
    /// Creates a new instance of TextureCropEncoder.
    ///
    /// - Parameters:
    ///   - context: Alloy's Metal context.
    public convenience init(context: MTLContext) throws {
        guard let library = context.shaderLibrary(for: TextureCropEncoder.self)
        else { throw Errors.libraryCreationFailed }
        try self.init(library: library)
    }
    
    /// Creates a new instance of TextureCropEncoder.
    ///
    /// - Parameters:
    ///   - library: Alloy's shader library.
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
        
        self.pipelineState = try library.computePipelineState(function: TextureCropEncoder.functionName,
                                                              constants: constantValues)
    }
    
    /// Encode TextureCropEncoder into command buffer.
    ///
    /// - Parameters:
    ///   - inputTexture: Original texture.
    ///   - outputTexture: Cropped texture.
    ///   - cropRect: Preffered crop region.
    ///   - commandBuffer: Command buffer to be used.
    public func encode(inputTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       cropRect: CropRect,
                       in commandBuffer: MTLCommandBuffer) {
        commandBuffer.compute { encoder in
            self.encode(inputTexture: inputTexture, outputTexture: outputTexture, cropRect: cropRect, using: encoder)
        }
    }
    
    /// Encode TextureCropEncoder using command encoder.
    ///
    /// - Parameters:
    ///   - inputTexture: Original texture.
    ///   - outputTexture: Cropped texture.
    ///   - cropRect: Preffered crop region.
    ///   - encoder: Command encoder to be used.
    public func encode(inputTexture: MTLTexture,
                       outputTexture: MTLTexture,
                       cropRect: CropRect,
                       using encoder: MTLComputeCommandEncoder) {
        encoder.pushDebugGroup("Texture Crop")
        encoder.set(textures: [inputTexture, outputTexture])
        encoder.set(cropRect, at: 0)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatch2d(state: self.pipelineState,
                               exactly: outputTexture.size)
        } else {
            encoder.dispatch2d(state: self.pipelineState,
                               covering: outputTexture.size)
        }
        encoder.popDebugGroup()
    }
    
    private static let functionName = "textureCrop"
}
