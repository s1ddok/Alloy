import Metal

public extension MTLFunctionConstantValues {

    // MARK: - Generic

    func set<T>(_ value: T,
                type: MTLDataType,
                at index: Int) {
        var t = value
        self.setConstantValue(&t,
                              type: type,
                              index: index)
    }

    func set<T>(_ values: [T],
                type: MTLDataType,
                startingAt startIndex: Int = 0) {
        self.setConstantValues(values,
                               type: type,
                               range: startIndex ..< (startIndex + values.count))
    }

    // MARK: - Bool

    func set(_ value: Bool,
             at index: Int) {
        self.set(value,
                 type: .bool,
                 at: index)
    }

    func set(_ values: [Bool],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .bool,
                 startingAt: startIndex)
    }

    // MARK: - Float

    func set(_ value: Float,
             at index: Int) {
        self.set(value,
                 type: .float,
                 at: index)
    }

    func set(_ values: [Float],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .float,
                 startingAt: startIndex)
    }

    // MARK: - Int32

    func set(_ value: Int32,
             at index: Int) {
        self.set(value,
                 type: .int,
                 at: index)
    }

    func set(_ values: [Int32],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .int,
                 startingAt: startIndex)
    }

    // MARK: - Int

    func set(_ value: Int,
             at index: Int) {
        self.set(Int32(value),
                 at: index)
    }

    func set(_ values: [Int],
             startingAt startIndex: Int = 0) {
        self.set(values.map { Int32($0) },
                 startingAt: startIndex)
    }

    // MARK: - UInt32

    func set(_ value: UInt32,
             at index: Int) {
        self.set(value,
                 type: .uint,
                 at: index)
    }

    func set(_ values: [UInt32],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .uint,
                 startingAt: startIndex)
    }

    // MARK: - UInt

    func set(_ value: UInt,
             at index: Int) {
        self.set(UInt32(value),
                 at: index)
    }

    func set(_ values: [UInt],
             startingAt startIndex: Int = 0) {
        self.set(values.map { UInt32($0) },
                 startingAt: startIndex)
    }

}
