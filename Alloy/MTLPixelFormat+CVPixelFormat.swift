//
//  MTLPixelFormat+CVPixelFormat.swift
//  Alloy
//
//  Created by Eugene Bokhan on 19.12.2019.
//

import Metal

public extension MTLPixelFormat {

    var compatibleCVPixelFormat: OSType? {
        switch self {
        case .r8Unorm, .r8Unorm_srgb: return kCVPixelFormatType_OneComponent8
        case .r16Float: return kCVPixelFormatType_OneComponent16Half
        case .r32Float: return kCVPixelFormatType_OneComponent32Float

        case .rg8Unorm, .rg8Unorm_srgb: return kCVPixelFormatType_TwoComponent8
        case .rg16Float: return kCVPixelFormatType_TwoComponent16Half
        case .rg32Float: return kCVPixelFormatType_TwoComponent32Float

        case .bgra8Unorm, .bgra8Unorm_srgb: return kCVPixelFormatType_32BGRA
        case .rgba8Unorm, .rgba8Unorm_srgb: return kCVPixelFormatType_32RGBA
        case .rgba16Float: return kCVPixelFormatType_64RGBAHalf
        case .rgba32Float: return kCVPixelFormatType_128RGBAFloat

        case .depth32Float: return kCVPixelFormatType_DepthFloat32
        default: return nil
        }
    }

}
