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
        let data = [Float32](repeating: .random(in: 0 ..< .init(self.numberOfElements)),
                             count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    @available(iOS 14.0, tvOS 14.0, *)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func testSortFloat16() throws {
        let data = [Swift.Float16](repeating: .random(in: 0 ..< .max),
                                   count: .init(Swift.Float16.max))
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortUInt32() throws {
        let data = [UInt32](repeating: .random(in: 0 ..< .init(self.numberOfElements)),
                            count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortUInt16() throws {
        let data = [UInt16](repeating: .random(in: 0 ..< .max),
                            count: .init(UInt16.max))
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortInt32() throws {
        let data = [Int32](repeating: .random(in: 0 ..< .init(self.numberOfElements)),
                           count: self.numberOfElements)
        let cpuSortedData = data.sorted()
        let gpuSortedData = try self.sortData(data)
        XCTAssertEqual(cpuSortedData, gpuSortedData)
    }

    func testSortInt16() throws {
        let data = [Int16](repeating: .random(in: 0 ..< .max),
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

}

@available(iOS 14.0, tvOS 14.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
extension Swift.Float16 {
    static let max: Swift.Float16 = 65504
}
