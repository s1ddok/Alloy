import Foundation

public struct BlockSize {
    public var width: UInt16
    public var height: UInt16

    public init(width: UInt16,
                height: UInt16) {
        self.width = width
        self.height = height
    }

    public init(width: Int,
                height: Int) {
        self.width = .init(width)
        self.height = .init(height)
    }
}
