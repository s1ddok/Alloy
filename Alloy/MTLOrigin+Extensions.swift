import Metal

public extension MTLOrigin {
    init(repeating value: Int) {
        self.init(x: value,
                  y: value,
                  z: value)
    }

    func clamped(to size: MTLSize) -> MTLOrigin {
        return MTLOrigin(x: min(max(self.x, 0), size.width),
                         y: min(max(self.y, 0), size.height),
                         z: min(max(self.z, 0), size.depth))
    }

    static let zero = MTLOrigin(repeating: 0)
    static func ==(lhs: MTLOrigin, rhs: MTLOrigin) -> Bool {
        return lhs.x == rhs.x
            && lhs.y == rhs.y
            && lhs.z == rhs.z
    }
    static func !=(lhs: MTLOrigin, rhs: MTLOrigin) -> Bool {
        return lhs.x != rhs.x
            || lhs.y != rhs.y
            || lhs.z != rhs.z
    }
}
