import XCTest
import Alloy
import MetalKit

@available(iOS 12.0, macOS 10.14, *)
final class MTLSharedBufferTests: XCTestCase {

    // MARK: - Errors

    enum Error: Swift.Error {
        case colorSpaceCreationFailed
        case bitmapInfoCreationFailed
    }

    // MARK: - Properties

    var context: MTLContext!
    var testPixelFormats: [MTLPixelFormat]!

    // MARK: - Setup

    override func setUpWithError() throws {
        self.context = try .init()
        self.testPixelFormats = [
            .r8Unorm, .r16Float, .r32Float,
            .bgra8Unorm, .bgra8Unorm_srgb, .rgba16Float, .rgba32Float
        ]
    }

    // MARK: - Testing

    func testBufferCrearion() throws {
        try self.testPixelFormats.forEach { pixelFormat in
            guard let colorSpace = pixelFormat.compatibleCGColorSpace
            else { throw Error.colorSpaceCreationFailed }
            guard let bitmapInfo = pixelFormat.compatibleCGBitmapInfo()
            else { throw Error.bitmapInfoCreationFailed }
            _ = try MTLSharedGraphicsBuffer(context: self.context,
                                            width: 256,
                                            height: 256,
                                            pixelFormat: pixelFormat,
                                            colorSpace: colorSpace,
                                            bitmapInfo: bitmapInfo)
        }
    }
}
