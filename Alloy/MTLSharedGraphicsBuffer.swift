import Foundation
import Accelerate
import Metal

@available(iOS 12.0, macOS 10.14, *)
final public class MTLSharedGraphicsBuffer {

    public enum Error: Swift.Error {
        case initializationFailed
        case unsupportedPixelFormat
    }

    public let texture: MTLTexture
    public let pixelBuffer: CVPixelBuffer
    public let buffer: MTLBuffer
    private(set) public var vImageBuffer: vImage_Buffer
    public let cgContext: CGContext
    public let pixelFormat: MTLPixelFormat
    public let cvPixelFormat: OSType
    public let rect: CGRect
    public let region: MTLRegion

    private var allocationPointer: UnsafeMutableRawPointer!

    public init(context: MTLContext,
                width: Int,
                height: Int,
                pixelFormat: MTLPixelFormat,
                colorSpace: CGColorSpace,
                bitmapInfo: UInt32,
                usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]) throws {
        guard let cvPixelFormat = pixelFormat.compatibleCVPixelFormat,
              let pixelFormatSize = pixelFormat.size,
              let bitsPerComponent = pixelFormat.bitsPerComponent
        else { throw Error.unsupportedPixelFormat }

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.usage = usage
        textureDescriptor.width = width
        textureDescriptor.height = height
        #if os(iOS) && !targetEnvironment(macCatalyst)
        textureDescriptor.storageMode = .shared
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        textureDescriptor.storageMode = .managed
        #endif

        // MARK: - Page align allocation pointer.

        /// The size of heap texture created from MTLBuffer.
        let heapTextureSizeAndAlign = context.heapTextureSizeAndAlign(descriptor: textureDescriptor)

        /// Current system's RAM page size.
        let pageSize = Int(getpagesize())

        /// Page aligned texture size.
        ///
        /// Get page aligned texture size.
        /// It might be more than raw texture size, but we'll alloccate memory in reserve.
        let pageAlignedTextureSize = alignUp(size: heapTextureSizeAndAlign.size,
                                             align: pageSize)

        /// Allocate `pageAlignedTextureSize` bytes and place the
        /// address of the allocated memory in `self.allocationPointer`.
        /// The address of the allocated memory will be a multiple of `pageSize` which is hardware friendly.
        posix_memalign(&self.allocationPointer,
                       pageSize,
                       heapTextureSizeAndAlign.size)

        // MARK: - Calculate bytes per row.

        /// Minimum texture alignment.
        ///
        /// The minimum alignment required when creating a texture buffer from a buffer.
        let textureBufferAlignment = context.minimumTextureBufferAlignment(for: pixelFormat)

        self.vImageBuffer = vImage_Buffer()

        /// Minimum vImage buffer alignment.
        ///
        /// Get the minimum data alignment required for buffer's contents,
        /// by passing `kvImageNoAllocate` to `vImage` constructor.
        let vImageBufferAlignment = vImageBuffer_Init(&self.vImageBuffer,
                                                      vImagePixelCount(height),
                                                      vImagePixelCount(width),
                                                      UInt32(bitsPerComponent),
                                                      vImage_Flags(kvImageNoAllocate))

        /// Pixel row alignment.
        ///
        /// Choose the maximum of previosly calculated alignments.
        let pixelRowAlignment = [textureBufferAlignment, vImageBufferAlignment].max()!

        let rowSize = pixelFormatSize * width

        /// Bytes per row.
        ///
        /// Calculate bytes per row by aligning row size with previously calculated `pixelRowAlignment`.
        let bytesPerRow = alignUp(size: rowSize,
                                  align: pixelRowAlignment)


        let pixelBufferAttributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ] as CFDictionary

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
                                                               cvPixelFormat,
                                                               self.allocationPointer!,
                                                               bytesPerRow,
                                                               nil, nil,
                                                               pixelBufferAttributes,
                                                               &trialPixelBuffer),
              let pixelBuffer = trialPixelBuffer,
              let cgContext = CGContext(data: self.allocationPointer!,
                                        width:width,
                                        height: height,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo)
        else { throw Error.initializationFailed }

        self.vImageBuffer.rowBytes = bytesPerRow
        self.vImageBuffer.data = self.allocationPointer
        self.buffer = buffer
        self.texture = texture
        self.pixelBuffer = pixelBuffer
        self.cgContext = cgContext
        self.pixelFormat = pixelFormat
        self.cvPixelFormat = cvPixelFormat
        self.region = self.texture.region
        self.rect = .init(origin: .zero,
                          size: .init(width: self.texture.width,
                                      height: self.texture.height))
    }
}

