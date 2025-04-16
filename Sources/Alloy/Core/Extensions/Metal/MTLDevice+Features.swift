import Metal

public enum Feature {
    case nonUniformThreadgroups
    case readWriteTextures(MTLPixelFormat)
}

public extension MTLDevice {
    func supports(feature: Feature) -> Bool {
        switch feature {
        case .nonUniformThreadgroups:
            #if targetEnvironment(macCatalyst)
            return self.supportsFamily(.common3)
            #elseif os(iOS)
            return self.supportsFeatureSet(.iOS_GPUFamily4_v1)
            #elseif os(macOS)
            return self.supportsFeatureSet(.macOS_GPUFamily1_v3)
            #elseif os(visionOS)
            return self.supportsFamily(.common2)
            #endif
            
        case let .readWriteTextures(pixelFormat):
            let tierOneSupportedPixelFormats: Set<MTLPixelFormat> = [
                .r32Float, .r32Uint, .r32Sint
            ]
            let tierTwoSupportedPixelFormats: Set<MTLPixelFormat> = tierOneSupportedPixelFormats.union([
                .rgba32Float, .rgba32Uint, .rgba32Sint, .rgba16Float,
                .rgba16Uint, .rgba16Sint, .rgba8Unorm, .rgba8Uint,
                .rgba8Sint, .r16Float, .r16Uint, .r16Sint,
                .r8Unorm, .r8Uint, .r8Sint
            ])
            
            switch self.readWriteTextureSupport {
            case .tier1: return tierOneSupportedPixelFormats.contains(pixelFormat)
            case .tier2: return tierTwoSupportedPixelFormats.contains(pixelFormat)
            case .tierNone: return false
            @unknown default: return false
            }
        }
    }
}
