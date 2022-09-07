import Metal

public class MTLTextureCodableBox: Codable {
    private let descriptor: MTLTextureDescriptorCodableBox
    private var data: Data

    public init(texture: MTLTexture) throws {
        let descriptor = texture.descriptor
        self.descriptor = .init(descriptor: descriptor)

        let sizeAndAlign = texture.device.heapTextureSizeAndAlign(descriptor: descriptor)

        var data = Data(count: sizeAndAlign.size)
        try data.withUnsafeMutableBytes { p in
            let pointer = p.baseAddress!

            guard let pixelFormatSize = texture.pixelFormat.size
            else { throw MetalError.MTLTextureSerializationError.unsupportedPixelFormat }

            var offset = 0

            for slice in 0..<texture.arrayLength {
                for mipMaplevel in 0..<texture.mipmapLevelCount {
                    guard let textureView = texture.makeTextureView(pixelFormat: texture.pixelFormat,
                                                                    textureType: texture.textureType,
                                                                    levels: mipMaplevel..<mipMaplevel+1,
                                                                    slices: slice..<slice+1)
                    else { throw MetalError.MTLTextureSerializationError.dataAccessFailure }

                    var bytesPerRow = pixelFormatSize * textureView.width * textureView.sampleCount
                    let bytesPerImage = bytesPerRow * textureView.height

                    // This comes from docs
                    // > When you copy pixels from a MTLTextureType1D or MTLTextureType1DArray texture, use 0.
                    if texture.textureType == .type1D || texture.textureType == .type1DArray {
                        bytesPerRow = 0
                    }

                    textureView.getBytes(pointer.advanced(by: offset),
                                         bytesPerRow: bytesPerRow,
                                         bytesPerImage: bytesPerImage,
                                         from: textureView.region,
                                         mipmapLevel: 0,
                                         slice: 0)

                    offset += bytesPerImage
                }
            }
        }

        self.data = data
    }

    public func texture(device: MTLDevice) throws -> MTLTexture {
        guard let texture = device.makeTexture(descriptor: self.descriptor.descriptor)
        else { throw MetalError.MTLTextureSerializationError.allocationFailed }

        try self.data.withUnsafeMutableBytes { p in
            let pointer = p.baseAddress!

            guard let pixelFormatSize = texture.pixelFormat.size
            else { throw MetalError.MTLTextureSerializationError.unsupportedPixelFormat }

            var offset = 0

            for slice in 0..<texture.arrayLength {
                for mipMaplevel in 0..<texture.mipmapLevelCount {
                    guard let textureView = texture.makeTextureView(pixelFormat: texture.pixelFormat,
                                                                    textureType: texture.textureType,
                                                                    levels: mipMaplevel..<mipMaplevel+1,
                                                                    slices: slice..<slice+1)
                    else { throw MetalError.MTLTextureSerializationError.dataAccessFailure }

                    var bytesPerRow = pixelFormatSize * textureView.width * textureView.sampleCount
                    let bytesPerImage = bytesPerRow * textureView.height

                    // This comes from docs
                    // > When you copy pixels from a MTLTextureType1D or MTLTextureType1DArray texture, use 0.
                    if texture.textureType == .type1D || texture.textureType == .type1DArray {
                        bytesPerRow = 0
                    }

                    textureView.replace(region: textureView.region,
                                        mipmapLevel: 0,
                                        slice: 0,
                                        withBytes: pointer.advanced(by: offset),
                                        bytesPerRow: bytesPerRow,
                                        bytesPerImage: bytesPerImage)

                    offset += bytesPerImage
                }
            }
        }

        return texture
    }
}

public extension MTLTexture {
    func codable() throws -> MTLTextureCodableBox {
        return try .init(texture: self)
    }
}
