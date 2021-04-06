import XCTest
import Alloy

final class BitonicSortTests: XCTestCase {

    enum Error: Swift.Error {
        case missingData
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

    func sortData<T: MetalCompatibleScalar>(_ data: [T]) throws -> [T] {
        let bitonicSort: BitonicSort<T> = try .init(context: self.context)
        try bitonicSort.setData(data)
        try self.context.scheduleAndWait(bitonicSort.encode(in:))
        guard let result = bitonicSort.getData()
        else { throw Error.missingData }
        return result
    }

    func testPerformance() throws {
        let data = [Float32](random: 0 ..< .init(self.numberOfElements),
                             count: self.numberOfElements)

        let bitonicSort: BitonicSort<Float32> = try .init(context: self.context)
        try bitonicSort.setData(data)

        self.measure {
            try? self.context.scheduleAndWait(bitonicSort.encode(in:))
        }
    }

}

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
extension Swift.Float16 {
    static let max: Swift.Float16 = 65504
}

extension Array where Element == Float32 {
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
extension Array where Element == Swift.Float16 {
    init(random range: Range<Swift.Float16>, count: Int) {
        var array = [Swift.Float16](repeating: .zero,
                                    count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

extension Array where Element == UInt32 {
    init(random range: Range<UInt32>, count: Int) {
        var array = [UInt32](repeating: .zero,
                              count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

extension Array where Element == UInt16 {
    init(random range: Range<UInt16>, count: Int) {
        var array = [UInt16](repeating: .zero,
                             count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

extension Array where Element == Int32 {
    init(random range: Range<Int32>, count: Int) {
        var array = [Int32](repeating: .zero,
                            count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}

extension Array where Element == Int16 {
    init(random range: Range<Int16>, count: Int) {
        var array = [Int16](repeating: .zero,
                              count: count)
        for i in 0 ..< array.count {
            array[i] = .random(in: range)
        }
        self = array
    }
}
