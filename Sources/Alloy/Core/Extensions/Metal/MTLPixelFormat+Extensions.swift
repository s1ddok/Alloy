import Metal

public extension MTLPixelFormat {
    enum ScalarType: String {
        case float, half, ushort, short, uint, int
    }

    var size: Int? {
        switch self {
        case .a8Unorm, .r8Unorm, .r8Snorm,
             .r8Uint, .r8Sint, .stencil8, .r8Unorm_srgb: return 1
        case .r16Unorm, .r16Snorm, .r16Uint,
             .r16Sint, .r16Float, .rg8Unorm,
             .rg8Snorm, .rg8Uint, .rg8Sint,
             .depth16Unorm, .rg8Unorm_srgb: return 2
        case .r32Uint, .r32Sint, .r32Float,
             .rg16Unorm, .rg16Snorm, .rg16Uint,
             .rg16Sint, .rg16Float, .rgba8Unorm,
             .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint,
             .rgba8Sint, .bgra8Unorm, .bgra8Unorm_srgb,
             .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float,
             .rgb9e5Float, .bgr10a2Unorm, .gbgr422,
             .bgrg422, .depth32Float, .depth24Unorm_stencil8,
             .x24_stencil8, .bgr10_xr_srgb, .bgr10_xr: return 4
        case .rg32Uint, .rg32Sint, .rg32Float,
             .rgba16Unorm, .rgba16Snorm, .rgba16Uint,
             .rgba16Sint, .rgba16Float, .bc1_rgba,
             .bc1_rgba_srgb, .depth32Float_stencil8, .x32_stencil8,
             .bgra10_xr, .bgra10_xr_srgb: return 8
        case .rgba32Uint, .rgba32Sint, .rgba32Float,
             .bc2_rgba, .bc2_rgba_srgb, .bc3_rgba,
             .bc3_rgba_srgb: return 16
        default:
            // TODO: Finish bc4-bc7
            return nil
        }
    }

    var isOrdinary8Bit: Bool {
        #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
        switch self {
        case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm, .r8Uint, .r8Sint:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        switch self {
        case .a8Unorm, .r8Unorm, .r8Snorm, .r8Uint, .r8Sint:
            return true
        default: return false
        }
        #endif
    }

    var isOrdinary16Bit: Bool {
        #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
        switch self {
        case .r16Unorm, .r16Snorm, .r16Uint, .r16Sint, .r16Float,
             .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm, .rg8Uint, .rg8Sint:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        switch self {
        case .r16Unorm, .r16Snorm, .r16Uint, .r16Sint, .r16Float,
             .rg8Unorm, .rg8Snorm, .rg8Uint, .rg8Sint:
            return true
        default: return false
        }
        #endif
    }

    var isPacked16Bit: Bool {
        #if (os(iOS) || os(visionOS))  && !targetEnvironment(macCatalyst)
        switch self {
        case .b5g6r5Unorm, .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        return false
        #endif
    }

    var isOrdinary32Bit: Bool {
        switch self {
        case .r32Uint, .r32Sint, .r32Float,
             .rg16Unorm,  .rg16Snorm, .rg16Uint, .rg16Sint, .rg16Float,
             .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint, .bgra8Unorm, .bgra8Unorm_srgb:
            return true
        default: return false
        }
    }

    var isPacked32Bit: Bool {
        #if (os(iOS) || os(visionOS))  && !targetEnvironment(macCatalyst)
        switch self {
        case .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float, .rgb9e5Float,
             .bgr10a2Unorm, .bgr10_xr, .bgr10_xr_srgb:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        switch self {
        case .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float, .rgb9e5Float,
             .bgr10a2Unorm:
            return true
        default: return false
        }
        #endif
    }

    var isNormal64Bit: Bool {
        #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
        switch self {
        case .rg32Uint, .rg32Sint, .rg32Float, .rgba16Unorm,
             .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float,
             .bgra10_xr, .bgra10_xr_srgb:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        switch self {
        case .rg32Uint, .rg32Sint, .rg32Float, .rgba16Unorm,
             .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float:
            return true
        default: return false
        }
        #endif
    }

    var isNormal128Bit: Bool {
        switch self {
        case .rgba32Uint, .rgba32Sint, .rgba32Float:
            return true
        default: return false
        }
    }

    var isSRGB: Bool {
        #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
        switch self {
        case .bgra8Unorm_srgb, .bgr10_xr_srgb, .bgra10_xr_srgb,
             .r8Unorm_srgb, .rg8Unorm_srgb,
             .rgba8Unorm_srgb,
             .astc_4x4_srgb, .astc_5x4_srgb, .astc_5x5_srgb, .astc_6x5_srgb,
             .astc_6x6_srgb, .astc_8x5_srgb, .astc_8x6_srgb, .astc_8x8_srgb,
             .pvrtc_rgb_2bpp_srgb, .pvrtc_rgb_4bpp_srgb, .pvrtc_rgba_2bpp_srgb, .pvrtc_rgba_4bpp_srgb,
             .etc2_rgb8a1_srgb, .etc2_rgb8_srgb, .eac_rgba8_srgb:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        switch self {
        case .bgra8Unorm_srgb, .rgba8Unorm_srgb, .bc1_rgba_srgb,
             .bc2_rgba_srgb, .bc3_rgba_srgb, .bc7_rgbaUnorm_srgb:
            return true
        default: return false
        }
        #endif
    }

    var isExtendedRange: Bool {
        #if (os(iOS) || os(visionOS))  && !targetEnvironment(macCatalyst)
        switch self {
        case .bgr10_xr, .bgr10_xr_srgb,
             .bgra10_xr, .bgra10_xr_srgb:
            return true
        default: return false
        }
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        return false
        #endif
    }

    var isCompressed: Bool {
        #if (os(iOS) || os(visionOS))  && !targetEnvironment(macCatalyst)
        return self.isPVRTC
            || self.isEAC
            || self.isETC
            || self.isASTC
            || self.isHDRASTC
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        return self.isS3TC
            || self.isRGTC
            || self.isBPTC
        #endif
    }

    #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)

    var isPVRTC: Bool {
        switch self {
            case .pvrtc_rgb_2bpp, .pvrtc_rgb_2bpp_srgb, .pvrtc_rgb_4bpp, .pvrtc_rgb_4bpp_srgb,
                 .pvrtc_rgba_2bpp, .pvrtc_rgba_2bpp_srgb, .pvrtc_rgba_4bpp, .pvrtc_rgba_4bpp_srgb:
                return true
        default: return false
        }
    }

    var isASTC: Bool {
        switch self {
            case .astc_4x4_srgb, .astc_5x4_srgb, .astc_5x5_srgb, .astc_6x5_srgb, .astc_6x6_srgb, .astc_8x5_srgb,
                 .astc_8x6_srgb, .astc_8x8_srgb, .astc_10x5_srgb, .astc_10x6_srgb, .astc_10x8_srgb, .astc_10x10_srgb,
                 .astc_12x10_srgb, .astc_12x12_srgb, .astc_4x4_ldr, .astc_5x4_ldr, .astc_5x5_ldr, .astc_6x5_ldr,
                 .astc_6x6_ldr, .astc_8x5_ldr, .astc_8x6_ldr, .astc_8x8_ldr, .astc_10x5_ldr, .astc_10x6_ldr,
                 .astc_10x8_ldr, .astc_10x10_ldr, .astc_12x10_ldr, .astc_12x12_ldr:
                return true
        default: return false
        }
    }

    var isHDRASTC: Bool {
        switch self {
        case .astc_4x4_hdr,
             .astc_5x4_hdr, .astc_5x5_hdr,
             .astc_6x5_hdr, .astc_6x6_hdr,
             .astc_8x5_hdr, .astc_8x6_hdr, .astc_8x8_hdr,
             .astc_10x5_hdr, .astc_10x6_hdr, .astc_10x8_hdr, .astc_10x10_hdr,
             .astc_12x10_hdr, .astc_12x12_hdr:
                return true
        default: return false
        }
    }


    var isETC: Bool {
        switch self {
        case .etc2_rgb8, .etc2_rgb8_srgb, .etc2_rgb8a1, .etc2_rgb8a1_srgb:
            return true
        default: return false
        }
    }

    var isEAC: Bool {
        switch self {
        case .eac_r11Unorm, .eac_r11Snorm, .eac_rg11Unorm,
             .eac_rg11Snorm, .eac_rgba8, .eac_rgba8_srgb:
            return true
        default: return false
        }
    }

    #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))

    var isS3TC: Bool {
        switch self {
        case .bc1_rgba, .bc1_rgba_srgb,
             .bc2_rgba, .bc2_rgba_srgb,
             .bc3_rgba, .bc3_rgba_srgb:
            return true
        default: return false
        }
    }

    var isRGTC: Bool {
        switch self {
        case .bc4_rUnorm, .bc4_rSnorm,
             .bc5_rgUnorm, .bc5_rgSnorm:
            return true
        default: return false
        }
    }

    var isBPTC: Bool {
        switch self {
        case .bc6H_rgbFloat, .bc6H_rgbuFloat,
             .bc7_rgbaUnorm, .bc7_rgbaUnorm_srgb:
            return true
        default: return false
        }
    }

    #endif

    var isYUV: Bool {
        switch self {
        case .gbgr422, .bgrg422:
            return true
        default: return false
        }
    }

    var isDepth: Bool {
        switch self {
        case .depth16Unorm, .depth32Float:
            return true
        default: return false
        }
    }

    var isStencil: Bool {
        switch self {
        case .stencil8, .depth32Float_stencil8, .x32_stencil8:
            return true
        default: return false
        }
    }

    var isRenderable: Bool {
        // Depth, stencil, YUV & compressed pixel formats check.
        guard !(self.isDepth   ||
                self.isStencil ||
                self.isYUV     ||
                self.isCompressed)
        else { return false }

        switch self {
        case .a8Unorm:
            return false
        case .rgb9e5Float:
            #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
            return true
            #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
            return false
            #endif
        default: return true
        }
    }

}
