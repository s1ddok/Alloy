import Metal

public extension MTLPixelFormat {

    var compatibleCGColorSpace: CGColorSpace? {
        if self.componentCount == 1 {
            return CGColorSpaceCreateDeviceGray()
        } else if self.componentCount == 4 {
            return CGColorSpaceCreateDeviceRGB()
        }
        return nil
    }

    func compatibleCGBitmapInfo(premultipliedAlpha: Bool = false) -> UInt32? {
        let alphaFirstInfo = premultipliedAlpha
                           ? CGImageAlphaInfo.noneSkipFirst.rawValue
                           : CGImageAlphaInfo.premultipliedFirst.rawValue
        let alphaLastInfo = premultipliedAlpha
                          ? CGImageAlphaInfo.noneSkipLast.rawValue
                          : CGImageAlphaInfo.premultipliedLast.rawValue
        switch self {
        case .bgra8Unorm, .bgra8Unorm_srgb:
            return CGBitmapInfo.byteOrder32Little.rawValue | alphaFirstInfo
        case .rgba8Unorm, .rgba8Unorm_srgb:
            return CGBitmapInfo.byteOrder32Little.rawValue | alphaLastInfo
        case .rgba16Float:
            return CGBitmapInfo.floatComponents.rawValue | alphaLastInfo
        case .r16Float:
            return CGBitmapInfo.floatInfoMask.rawValue
        case .r8Unorm, .r8Unorm_srgb, .r8Snorm:
            return CGBitmapInfo.alphaInfoMask.rawValue
        default: return nil
        }
    }

}
