//
//  MTLPixelFormat+Size.swift
//  Alloy
//
//  Created by Andrey Volodin on 27/08/2019.
//

import Metal

public extension MTLPixelFormat {
    var size: Int? {
        switch self {
        case .a8Unorm, .r8Unorm, .r8Snorm,
             .r8Uint, .r8Sint, .stencil8: return 1
        case .r16Unorm, .r16Snorm, .r16Uint,
             .r16Sint, .r16Float, .rg8Unorm,
             .rg8Snorm, .rg8Uint, .rg8Sint,
             .depth16Unorm: return 2
        case .r32Uint, .r32Sint, .r32Float,
             .rg16Unorm, .rg16Snorm, .rg16Uint,
             .rg16Sint, .rg16Float, .rgba8Unorm,
             .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint,
             .rgba8Sint, .bgra8Unorm, .bgra8Unorm_srgb,
             .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float,
             .rgb9e5Float, .bgr10a2Unorm, .gbgr422,
             .bgrg422, .depth32Float, .depth24Unorm_stencil8,
             .x24_stencil8: return 4
        case .rg32Uint, .rg32Sint, .rg32Float,
             .rgba16Unorm, .rgba16Snorm, .rgba16Uint,
             .rgba16Sint, .rgba16Float, .bc1_rgba,
             .bc1_rgba_srgb, .depth32Float_stencil8, .x32_stencil8: return 8
        case .rgba32Uint, .rgba32Sint, .rgba32Float,
             .bc2_rgba, .bc2_rgba_srgb, .bc3_rgba,
             .bc3_rgba_srgb: return 16
        default:
            // TODO: Finish bc4-bc7
            return nil
        }
    }
}
