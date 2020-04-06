import Foundation
import Alloy

@available(iOS 12.0, *)
final public class MTLCVBuffer {

    public enum Error: Swift.Error {
        case initializationFailed
    }

    public let texture: MTLTexture
    public let pixelBuffer: CVPixelBuffer
    public let buffer: MTLBuffer

    private var allocationPointer: UnsafeMutableRawPointer!

    public init(context: MTLContext,
                width: Int,
                height: Int,
                pixelFormat: MTLPixelFormat = .bgra8Unorm,
                usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]) throws {
        let textureDescriptor = MTLTextureDescriptor()
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

        var trialPixelBuffer: CVPixelBuffer?
        guard let buffer = context.buffer(bytesNoCopy: self.allocationPointer,
                                          length: pageAlignedTextureSize,
                                          options: .storageModeShared,
                                          deallocator: nil),
              let texture = buffer.makeTexture(descriptor: textureDescriptor,
                                               offset: 0,
                                               bytesPerRow: bytesPerRow),
              kCVReturnSuccess == CVPixelBufferCreateWithBytes(nil,
                                                               width,
                                                               height,
                                                               kCVPixelFormatType_32BGRA,
                                                               self.allocationPointer!,
                                                               bytesPerRow,
                                                               nil, nil, nil,
                                                               &trialPixelBuffer),
              let pixelBuffer = trialPixelBuffer
        else { throw Error.initializationFailed }

        self.buffer = buffer
        self.texture = texture
        self.pixelBuffer = pixelBuffer
    }

}
