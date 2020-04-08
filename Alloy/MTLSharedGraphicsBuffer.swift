import Foundation
import Alloy

@available(iOS 12.0, *)
final public class MTLSharedGraphicsBuffer {

    public enum SupportedPixelFormat {
        case bgra8Unorm

        var mtlPixelFormat: MTLPixelFormat {
            switch self {
            case .bgra8Unorm:
                return .bgra8Unorm
            }
        }
    }

    public enum Error: Swift.Error {
        case initializationFailed
    }

    public let texture: MTLTexture
    public let pixelBuffer: CVPixelBuffer
    public let buffer: MTLBuffer
    public var rect: CGRect {
        let size = CGSize(width: self.texture.width,
                          height: self.texture.height)
        return .init(origin: .zero,
                     size: size)
    }
    public var region: MTLRegion {
        self.texture.region
    }
    
    public var cgImage: CGImage {
        get { self.cgContext.makeImage()! }
        set { self.cgContext.draw(newValue, in: self.rect) }
    }
    public var image: UIImage {
        .init(cgImage: self.cgImage)
    }

    private let cgContext: CGContext
    private var allocationPointer: UnsafeMutableRawPointer!

    public convenience init(context: MTLContext,
                            cgImage: CGImage,
                            pixelFormat: SupportedPixelFormat = .bgra8Unorm,
                            usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]) throws {
        try self.init(context: context,
                      width: cgImage.width,
                      height: cgImage.height,
                      pixelFormat: pixelFormat,
                      usage: usage)
        self.cgImage = cgImage
    }

    public init(context: MTLContext,
                width: Int,
                height: Int,
                pixelFormat: SupportedPixelFormat = .bgra8Unorm,
                usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]) throws {
        let textureDescriptor = MTLTextureDescriptor()
        let pixelFormat = pixelFormat.mtlPixelFormat
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.usage = usage
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.storageMode = .shared

        guard let pixelFormatSize = pixelFormat.size
        else { throw Error.initializationFailed }

        let pageSize = Int(getpagesize())
        let heapTextureSize = context.heapTextureSizeAndAlign(descriptor: textureDescriptor)
                                     .size
        let pageAlignedTextureSize = alignUp(size: heapTextureSize,
                                             align: pageSize)
        let pixelRowAlignment = context.minimumTextureBufferAlignment(for: pixelFormat)
        let bytesPerRow = alignUp(size: pixelFormatSize * width,
                                  align: pixelRowAlignment)

        posix_memalign(&self.allocationPointer,
                       pageSize,
                       pageAlignedTextureSize)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
                       | CGImageAlphaInfo.premultipliedFirst.rawValue
        var trialPixelBuffer: CVPixelBuffer?
        guard let buffer = context.buffer(bytesNoCopy: self.allocationPointer,
                                          length: pageAlignedTextureSize,
                                          options: .storageModeShared,
                                          deallocator: nil),
              let texture = buffer.makeTexture(descriptor: textureDescriptor,
                                               offset: 0,
                                               bytesPerRow: bytesPerRow),
              let cvPixelFormat = pixelFormat.compatibleCVPixelFormat,
              kCVReturnSuccess == CVPixelBufferCreateWithBytes(nil,
                                                               width,
                                                               height,
                                                               cvPixelFormat,
                                                               self.allocationPointer!,
                                                               bytesPerRow,
                                                               nil, nil, nil,
                                                               &trialPixelBuffer),
              let pixelBuffer = trialPixelBuffer,
              let bitsPerComponent = pixelFormat.bitsPerComponent,
              let cgContext = CGContext(data: self.allocationPointer!,
                                        width:width,
                                        height: height,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo)
        else { throw Error.initializationFailed }

        self.buffer = buffer
        self.texture = texture
        self.pixelBuffer = pixelBuffer
        self.cgContext = cgContext
    }

}

