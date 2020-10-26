import XCTest
import Alloy

final class TextureCopyTests: XCTestCase {
    
    // MARK: - Type Definitions

    struct TestCase {
        let sourceRegion: MTLRegion
        let destinationOrigin: MTLOrigin
        let source: MTLTexture
        let destination: MTLTexture
        let reference: MTLTexture
    }

    // MARK: - Properties

    public var context: MTLContext!
    public var euclideanDistanceFloat: EuclideanDistance!
    public var textureCopy: TextureCopy!
    public var testCases: [TestCase]!

    // MARK: - Setup

    override func setUpWithError() throws {
        self.context = try .init()
        self.euclideanDistanceFloat = try .init(context: self.context,
                                                scalarType: .float)
        self.textureCopy = try .init(context: self.context,
                                     scalarType: .float)

        let jsonDecoder = JSONDecoder()
        let testCasesFolderURL = Bundle.alloyTestsResources.url(forResource: Self.testResourcesFolderName,
                                                                withExtension: nil)!
        
        let testCasesURLs = try FileManager.default.contentsOfDirectory(at: testCasesFolderURL,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: [])
        self.testCases = try testCasesURLs.map { testCaseFolderURL -> TextureCopyTests.TestCase in
            let sourceRegionFileURL = testCaseFolderURL.appendingPathComponent("\(Self.sourceRegionFileName)")
            let destinationOriginFileURL = testCaseFolderURL.appendingPathComponent("\(Self.destinationOriginFileName)")
            let sourceImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.sourceTextureFileName)")
            let destinationImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.destinationTextureFileName)")
            let referenceImageFileURL = testCaseFolderURL.appendingPathComponent("\(Self.referenceTextureFileName)")

            let sourceRegionData = try Data(contentsOf: sourceRegionFileURL)
            let destinationOriginData = try Data(contentsOf: destinationOriginFileURL)
                                                                            
            let sourceRegion = try jsonDecoder.decode(MTLRegion.self,
                                                      from: sourceRegionData)
            let destinationOrigin = try jsonDecoder.decode(MTLOrigin.self,
                                                           from: destinationOriginData)
            let source = try self.context.texture(from: .initFromURL(sourceImageFileURL),
                                                  usage: [.shaderRead, .shaderWrite])
            let destination = try self.context.texture(from: .initFromURL(destinationImageFileURL),
                                                       usage: [.shaderRead, .shaderWrite])
            let reference = try self.context.texture(from: .initFromURL(referenceImageFileURL),
                                                     usage: [.shaderRead, .shaderWrite])

            return .init(sourceRegion: sourceRegion,
                         destinationOrigin: destinationOrigin,
                         source: source,
                         destination: destination,
                         reference: reference)
        }
    }

    // MARK: - Testing

    func testTextureCopy() throws {
        let resultBuffer = try self.context.buffer(for: Float.self,
                                                   options: .storageModeShared)
        
        try self.testCases.forEach { testCase in
            try self.context.scheduleAndWait { commandBuffer in
                self.textureCopy(region: testCase.sourceRegion,
                                 from: testCase.source,
                                 to: testCase.destinationOrigin,
                                 of: testCase.destination,
                                 in: commandBuffer)

                self.euclideanDistanceFloat(textureOne: testCase.destination,
                                            textureTwo: testCase.reference,
                                            resultBuffer: resultBuffer,
                                            in: commandBuffer)
            }

            let result = resultBuffer.pointer(of: Float.self)!.pointee
            XCTAssert(result < 0.05)
        }
    }

    static let testResourcesFolderName = "TextureCopy"
    static let sourceRegionFileName = "source_region.json"
    static let destinationOriginFileName = "destination_origin.json"
    static let sourceTextureFileName = "source.png"
    static let destinationTextureFileName = "destination.png"
    static let referenceTextureFileName = "reference.png"
}
