import Metal

internal class MTLTextureDescriptorCodableBox: Codable {
    let descriptor: MTLTextureDescriptor

    init(descriptor: MTLTextureDescriptor) {
        self.descriptor = descriptor
    }

    required init(from decoder: Decoder) throws {
        self.descriptor = try MTLTextureDescriptor(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try self.descriptor.encode(to: encoder)
    }
}

extension MTLTextureDescriptor: Encodable {

    internal enum CodingKeys: String, CodingKey {
        case width
        case height
        case depth
        case arrayLength
        case storageMode
        case cpuCacheMode
        case usage
        case textureType
        case sampleCount
        case mipmapLevelCount
        case pixelFormat
        case allowGPUOptimizedContents
    }

    public convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.arrayLength = try container.decode(Int.self, forKey: .arrayLength)
        self.cpuCacheMode = try container.decode(MTLCPUCacheMode.self, forKey: .cpuCacheMode)
        self.usage = try container.decode(MTLTextureUsage.self, forKey: .usage)
        self.textureType = try container.decode(MTLTextureType.self, forKey: .textureType)
        self.sampleCount = try container.decode(Int.self, forKey: .sampleCount)
        self.mipmapLevelCount = try container.decode(Int.self, forKey: .mipmapLevelCount)
        self.pixelFormat = try container.decode(MTLPixelFormat.self, forKey: .pixelFormat)

        if #available(iOS 12, macOS 10.14, *) {
            self.allowGPUOptimizedContents = (try? container.decode(Bool.self, forKey: .allowGPUOptimizedContents)) ?? true
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        try container.encode(self.depth, forKey: .depth)
        try container.encode(self.arrayLength, forKey: .arrayLength)
        try container.encode(self.cpuCacheMode, forKey: .cpuCacheMode)
        try container.encode(self.usage, forKey: .usage)
        try container.encode(self.textureType, forKey: .textureType)
        try container.encode(self.sampleCount, forKey: .sampleCount)
        try container.encode(self.mipmapLevelCount, forKey: .mipmapLevelCount)
        try container.encode(self.pixelFormat, forKey: .pixelFormat)

        if #available(iOS 12, macOS 10.14, *) {
            try container.encode(self.allowGPUOptimizedContents, forKey: .allowGPUOptimizedContents)
        }
    }
}
