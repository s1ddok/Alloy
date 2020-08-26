import XCTest
import Alloy

final class TextureCopyTests: XCTestCase {

    // MARK: - Errors

    enum Error: Swift.Error {
        case cgImageCreationFailed
    }

    struct TestCase {
        let sourceRegion: MTLRegion
        let destinationOrigin: MTLOrigin
        let source: MTLTexture
        let destination: MTLTexture
        let desiredResult: MTLTexture

        init(context: MTLContext,
             sourceRegion: MTLRegion,
             destinationOrigin: MTLOrigin,
             sourceImage: CGImage,
             destinationImage: CGImage,
             desiredResultImage: CGImage) throws {
            self.sourceRegion = sourceRegion
            self.destinationOrigin = destinationOrigin
            try self.source = context.texture(from: sourceImage,
                                              usage: [.shaderRead, .shaderWrite])
            try self.destination = context.texture(from: destinationImage,
                                                   usage: [.shaderRead, .shaderWrite])
            try self.desiredResult = context.texture(from: desiredResultImage,
                                                     usage: [.shaderRead, .shaderWrite])
        }
    }

    // MARK: - Properties

    public var context: MTLContext!
    public var euclideanDistanceFloat: EuclideanDistance!
    public var textureCopy: TextureCopy!
    public var testCases: [TestCase]!

    // MARK: - Setup

    override func setUp() {
        do {
            self.context = try .init()
            self.euclideanDistanceFloat = try .init(context: self.context,
                                                    scalarType: .float)
            self.textureCopy = try .init(context: self.context,
                                                scalarType: .float)

            let bundle = Bundle(for: Self.self)
            let jsonDecoder = JSONDecoder()
            let testCasesFolderURL = bundle.url(forResource: Self.testCasesFolderName,
                                                withExtension: nil)!

            self.testCases = try FileManager.default
                                            .contentsOfDirectory(at: testCasesFolderURL,
                                                                 includingPropertiesForKeys: nil,
                                                                 options: [])
                                            .map { testCaseFolderURL -> TextureCopyTests.TestCase in
                let sourceRegionFileURL = testCaseFolderURL.appendingPathComponent("\(Self.sourceRegionFileName)")
                let destinationOriginFileURL = testCaseFolderURL.appendingPathComponent("\(Self.destinationOriginFileName)")
                let sourceImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.sourceImageFileName)")
                let destinationImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.destinationImageFileName)")
                let desiredResultImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.desiredResultImageFileName)")

                let sourceRegionData = try Data(contentsOf: sourceRegionFileURL)
                let destinationOriginData = try Data(contentsOf: destinationOriginFileURL)
                let sourceImageData = try Data(contentsOf: sourceImageFileURL)
                let destinationImageData = try Data(contentsOf: destinationImageFileURL)
                let desiredResultImageData = try Data(contentsOf: desiredResultImageFileURL)

                guard let sourceCGImage = UIImage(data: sourceImageData)?.cgImage,
                      let destinationCGImage = UIImage(data: destinationImageData)?.cgImage,
                      let desiredResultCGImage = UIImage(data: desiredResultImageData)?.cgImage
                else { throw Error.cgImageCreationFailed }

                return try TestCase(context: self.context,
                                    sourceRegion: jsonDecoder.decode(MTLRegion.self,
                                                                     from: sourceRegionData),
                                    destinationOrigin: jsonDecoder.decode(MTLOrigin.self,
                                                                          from: destinationOriginData),
                                    sourceImage: sourceCGImage,
                                    destinationImage: destinationCGImage,
                                    desiredResultImage: desiredResultCGImage)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testTextureCopy() {
        do {
            // Setup results buffer.
            let resultBuffer = try self.context
                                       .buffer(for: Float.self,
                                               options: .storageModeShared)

            // Dispatch.
            try self.testCases.forEach { testCase in
                try self.context.scheduleAndWait { commandBuffer in
                    self.textureCopy(region: testCase.sourceRegion,
                                     from: testCase.source,
                                     to: testCase.destinationOrigin,
                                     of: testCase.destination,
                                     in: commandBuffer)

                    self.euclideanDistanceFloat(textureOne: testCase.destination,
                                                textureTwo: testCase.desiredResult,
                                                resultBuffer: resultBuffer,
                                                in: commandBuffer)
                }

                let result = resultBuffer.pointer(of: Float.self)!.pointee
                XCTAssert(result < 0.05)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static let testCasesFolderName = "texture_copy_test_cases"
    static let sourceRegionFileName = "sourceRegion.json"
    static let destinationOriginFileName = "destinationOrigin.json"
    static let sourceImageFileName = "sourceImage.png"
    static let destinationImageFileName = "destinationImage.png"
    static let desiredResultImageFileName = "desiredResultImage.png"
}
