import Metal

public extension MTLSize {
    init(repeating value: Int) {
        self.init(width: value,
                  height: value,
                  depth: value)
    }

    func clamped(to size: MTLSize) -> MTLSize {
        return MTLSize(width:  min(max(self.width, 0), size.width),
                       height: min(max(self.height, 0), size.height),
                       depth:  min(max(self.depth, 0), size.depth))
    }

    static let one = MTLSize(repeating: 1)
    static let zero = MTLSize(repeating: 0)
    static func ==(lhs: MTLSize, rhs: MTLSize) -> Bool {
        return lhs.width == rhs.width
            && lhs.height == rhs.height
            && lhs.depth == rhs.depth
    }
    static func !=(lhs: MTLSize, rhs: MTLSize) -> Bool {
        return lhs.width != rhs.width
            || lhs.height != rhs.height
            || lhs.depth != rhs.depth
    }
}
