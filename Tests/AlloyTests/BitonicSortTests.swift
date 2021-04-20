import XCTest
import Alloy

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
final class BitonicSortTests: XCTestCase {

    enum Error: Swift.Error {
        case missingData
        case unsupportedType
    }

    // MARK: - Properties

    public var context: MTLContext!
    private let numberOfElements = 99999

    // MARK: - Setup

    override func setUpWithError() throws {
        self.context = try .init()
    }

    func testSortFloat32() throws {
        let data = [Float32](random: 0 ..< .init(self.numberOfElements),
                             count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    @available(iOS 14.0, tvOS 14.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func testSortFloat16() throws {
        let data = [Swift.Float16](random: 0 ..< .max,
                                   count: .init(Swift.Float16.max))
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortUInt32() throws {
        let data = [UInt32](random: 0 ..< .init(self.numberOfElements),
                            count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortUInt16() throws {
        let data = [UInt16](random: 0 ..< .max,
                            count: .init(UInt16.max))
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortInt32() throws {
        let data = [Int32](random: 0 ..< .init(self.numberOfElements),
                           count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortInt16() throws {
        let data = [Int16](random: 0 ..< .max,
                           count: .init(Int16.max))
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func sortData<T: FloatingPoint>(_ data: [T]) throws -> [T] {
        guard let firstElement = data.first
        else { throw Error.missingData }

        let bitonicSort = try BitonicSort(context: self.context,
                                          scalarType: firstElement.scalarType())
        let buffer = try BitonicSort.buffer(from: data,
                                            device: self.context.device,
                                            options: .storageModeShared)

        try? self.context.scheduleAndWait { commandBuffer in
            bitonicSort(data: buffer.0,
                        count: buffer.1,
                        in: commandBuffer)
        }

        guard let result = buffer.buffer.array(of: T.self, count: data.count)
        else { throw Error.missingData }
        return result
    }

    func sortData<T: FixedWidthInteger>(_ data: [T]) throws -> [T] {
        guard let firstElement = data.first
        else { throw Error.missingData }

        let bitonicSort = try BitonicSort(context: self.context,
                                          scalarType: firstElement.scalarType())
        let buffer = try BitonicSort.buffer(from: data,
                                            device: self.context.device,
                                            options: .storageModeShared)

        try? self.context.scheduleAndWait { commandBuffer in
            bitonicSort(data: buffer.0,
                        count: buffer.1,
                        in: commandBuffer)
        }

        guard let result = buffer.buffer.array(of: T.self, count: data.count)
        else { throw Error.missingData }
        return result
    }

    func testPerformance() throws {
        let data = [Float32](random: 0 ..< .init(self.numberOfElements),
                             count: self.numberOfElements)

        let bitonicSort = try BitonicSort(context: self.context,
                                          scalarType: .float)
        let buffer = try BitonicSort.buffer(from: data,
                                            device: self.context.device,
                                            options: .storageModeShared)

        self.measure {
            try? self.context.scheduleAndWait { commandBuffer in
                bitonicSort(data: buffer.0,
                            count: buffer.1,
                            in: commandBuffer)
            }
        }
    }

}

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
private extension Numeric {

    func scalarType() throws -> MTLPixelFormat.ScalarType {
        switch self {
        case is Float32: return .float
        case is Swift.Float16: return .half
        case is UInt32: return .uint
        case is UInt16: return .ushort
        case is Int32: return .int
        case is Int16: return .short
        default: throw BitonicSortTests.Error.unsupportedType
        }
    }

}

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
private extension Swift.Float16 {
    static let max: Swift.Float16 = 65504
}

private extension Array where Element == Float32 {
    init(random range: Range<Float32>, count: Int) {
        var array = [Float32](repeating: .zero,
                              count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
private extension Array where Element == Swift.Float16 {
    init(random range: Range<Swift.Float16>, count: Int) {
        var array = [Swift.Float16](repeating: .zero,
                                    count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

private extension Array where Element == UInt32 {
    init(random range: Range<UInt32>, count: Int) {
        var array = [UInt32](repeating: .zero,
                             count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

private extension Array where Element == UInt16 {
    init(random range: Range<UInt16>, count: Int) {
        var array = [UInt16](repeating: .zero,
                             count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

private extension Array where Element == Int32 {
    init(random range: Range<Int32>, count: Int) {
        var array = [Int32](repeating: .zero,
                            count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

private extension Array where Element == Int16 {
    init(random range: Range<Int16>, count: Int) {
        var array = [Int16](repeating: .zero,
                            count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}
