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

    func compatibleCGBitmapInfo(alpha: CGAlphaInfo? = .premultiplied) -> UInt32? {
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
                alphaFirstInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            case .premultiplied:
                alphaFirstInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            }
        }

        switch self {
        case .bgra8Unorm, .bgra8Unorm_srgb:
            return CGBitmapInfo.byteOrder32Little.rawValue | alphaFirstInfo
        case .rgba8Unorm, .rgba8Unorm_srgb:
            return CGBitmapInfo.byteOrder32Big.rawValue | alphaLastInfo
        case .rgba16Float, .rgba32Float:
            let result = CGBitmapInfo.floatComponents.rawValue | alphaLastInfo
            return result
        case .r16Float:
            return CGBitmapInfo.floatInfoMask.rawValue
        case .r8Unorm, .r8Unorm_srgb, .r8Snorm:
            return CGBitmapInfo.alphaInfoMask.rawValue
        default: return nil
        }
    }

}
