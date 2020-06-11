import Alloy

extension MTLPixelFormat {

    enum PrecisionFormat {
        case halfPrecision
        case singlePrecision
    }

    enum DataFormat {
        case signedInteger
        case unsignedInteger
        case normalized
        case unknown
    }

    var dataFormat: DataFormat {
        switch self {
        case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm, .r16Unorm,
             .r16Snorm, .r16Float, .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm,
             .b5g6r5Unorm, .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm, .r32Float,
             .rg16Unorm, .rg16Snorm, .rg16Float, .rgba8Unorm, .rgba8Unorm_srgb,
             .rgba8Snorm, .bgra8Unorm, .bgra8Unorm_srgb, .rgb10a2Unorm, .rg11b10Float,
             .rgb9e5Float, .bgr10a2Unorm, .rg32Float, .rgba16Unorm, .rgba16Snorm,
             .rgba16Float, .rgba32Float, .eac_r11Unorm, .eac_r11Snorm, .eac_rg11Unorm,
             .eac_rg11Snorm, .depth32Float, .depth32Float_stencil8, .stencil8:
            return .normalized
        case .r8Sint, .r16Sint, .rg8Sint, .r32Sint, .rg16Sint,
             .rgba8Sint, .rg32Sint, .rgba16Sint, .rgba32Sint:
            return .signedInteger
        case .r8Uint, .r16Uint, .rg8Uint, .r32Uint, .rg16Uint,
             .rgba8Uint, .rgb10a2Uint, .rg32Uint, .rgba16Uint,
             .rgba32Uint:
            return .unsignedInteger
        default: return .unknown
        }
    }

    func scalarType(precisionFormat: PrecisionFormat) -> ScalarType? {
        switch self.dataFormat {
        case .signedInteger:
            switch precisionFormat {
            case .halfPrecision: return .short
            case .singlePrecision: return .int
            }
        case .unsignedInteger:
            switch precisionFormat {
            case .halfPrecision: return .ushort
            case .singlePrecision: return .uint
            }
        case .normalized:
            switch precisionFormat {
            case .halfPrecision: return .half
            case .singlePrecision: return .float
            }
        case .unknown:
            return nil
        }
    }

}
