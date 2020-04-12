import Metal

public extension MTLPixelFormat {

    enum CGAlphaInfo {
        case noneSkip
        case premultiplied
    }

    var compatibleCGColorSpace: CGColorSpace? {
        switch self.componentCount {
        case 1:
            return CGColorSpaceCreateDeviceGray()
        case 4:
            return CGColorSpaceCreateDeviceRGB()
        default:
            return nil
        }
    }

    func compatibleCGBitmapInfo(alpha: CGAlphaInfo? = .noneSkip) -> UInt32? {
        // AlphaFirst – the alpha channel is next to the red channel, argb and bgra are both alpha first formats.
        // AlphaLast – the alpha channel is next to the blue channel, rgba and abgr are both alpha last formats.
        // LittleEndian – blue comes before red, bgra and abgr are little endian formats.
        // Little endian ordered pixels are BGR (BGRX, XBGR, BGRA, ABGR, BGR).
        // BigEndian – red comes before blue, argb and rgba are big endian formats.
        // Big endian ordered pixels are RGB (XRGB, RGBX, ARGB, RGBA, RGB).

        // Valid parameters for RGB color space model are:
        // 16  bits per pixel, 5  bits per component, kCGImageAlphaNoneSkipFirst
        // 32  bits per pixel, 8  bits per component, kCGImageAlphaNoneSkipFirst
        // 32  bits per pixel, 8  bits per component, kCGImageAlphaNoneSkipLast
        // 32  bits per pixel, 8  bits per component, kCGImageAlphaPremultipliedFirst
        // 32  bits per pixel, 8  bits per component, kCGImageAlphaPremultipliedLast
        // 32  bits per pixel, 10 bits per component, kCGImageAlphaNone|kCGImagePixelFormatRGBCIF10
        // 64  bits per pixel, 16 bits per component, kCGImageAlphaPremultipliedLast
        // 64  bits per pixel, 16 bits per component, kCGImageAlphaNoneSkipLast
        // 64  bits per pixel, 16 bits per component, kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents
        // 64  bits per pixel, 16 bits per component, kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents
        // 128 bits per pixel, 32 bits per component, kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents
        // 128 bits per pixel, 32 bits per component, kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents

        var alphaFirstInfo: UInt32 = 0
        if let alpha = alpha {
            switch alpha {
            case .noneSkip:
                alphaFirstInfo = CGImageAlphaInfo.noneSkipFirst.rawValue
            case .premultiplied:
                alphaFirstInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
            }
        }

        var alphaLastInfo: UInt32 = 0
        if let alpha = alpha {
            switch alpha {
            case .noneSkip:
                alphaLastInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            case .premultiplied:
                alphaLastInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            }
        }

        switch self {
        case .bgra8Unorm, .bgra8Unorm_srgb:
            return alphaFirstInfo | CGBitmapInfo.byteOrder32Little.rawValue
        case .rgba8Unorm, .rgba8Unorm_srgb:
            return alphaLastInfo | CGBitmapInfo.byteOrder32Big.rawValue
        case .rgba16Float:
            return alphaLastInfo
        case .rgba32Float:
            return alphaLastInfo | CGBitmapInfo.floatComponents.rawValue
        case .r8Unorm, .r8Unorm_srgb, .r16Float:
            return CGImageAlphaInfo.none.rawValue
        case .r32Float:
            return CGBitmapInfo.floatInfoMask.rawValue
        default: return nil
        }
    }

}
