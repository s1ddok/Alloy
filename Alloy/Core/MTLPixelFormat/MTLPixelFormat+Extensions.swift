//
//  MTLPixelFormat+Size.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/08/2019.
//

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
    
    var isSRGB: Bool {
        switch self {
        case .bgra8Unorm_srgb, .bgr10_xr_srgb, .bgra10_xr_srgb,
             .r8Unorm_srgb, .rg8Unorm_srgb,
             .rgba8Unorm_srgb,
             .astc_4x4_srgb, .astc_5x4_srgb, .astc_5x5_srgb, .astc_6x5_srgb, .astc_6x6_srgb, .astc_8x5_srgb, .astc_8x6_srgb, .astc_8x8_srgb,
             .pvrtc_rgb_2bpp_srgb, .pvrtc_rgb_4bpp_srgb, .pvrtc_rgba_2bpp_srgb, .pvrtc_rgba_4bpp_srgb,
             .etc2_rgb8a1_srgb, .etc2_rgb8_srgb, .eac_rgba8_srgb:
            return true
        default: return false
        }
    }
}
