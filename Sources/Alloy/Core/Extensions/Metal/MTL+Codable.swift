import Metal

extension MTLCPUCacheMode: Codable {}
extension MTLTextureUsage: Codable {}
extension MTLTextureType: Codable {}
extension MTLPixelFormat: Codable {}

extension MTLOrigin: Codable {
    private enum CodingKeys: String, CodingKey {
        case x, y, z
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Int.self, forKey: .x)
        let y = try container.decode(Int.self, forKey: .y)
        let z = try container.decode(Int.self, forKey: .z)

        self.init(x: x, y: y, z: z)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.x, forKey: .x)
        try container.encode(self.y, forKey: .y)
        try container.encode(self.z, forKey: .z)
    }
}

extension MTLSize: Codable {
    private enum CodingKeys: String, CodingKey {
        case width, height, depth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Int.self, forKey: .width)
        let height = try container.decode(Int.self, forKey: .height)
        let depth = try container.decode(Int.self, forKey: .depth)

        self.init(width: width, height: height, depth: depth)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        try container.encode(self.depth, forKey: .depth)
    }
}

extension MTLRegion: Codable {
    private enum CodingKeys: String, CodingKey {
        case origin, size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let origin = try container.decode(MTLOrigin.self, forKey: .origin)
        let size = try container.decode(MTLSize.self, forKey: .size)

        self.init(origin: origin, size: size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.origin, forKey: .origin)
        try container.encode(self.size, forKey: .size)
    }
}
