import XCTest
import Alloy

final class EuclideanDistanceTests: XCTestCase {

    // MARK: - Properties

    var context: MTLContext!
    var euclideanDistanceFloat: EuclideanDistance!
    var textureAddConstantFloat: TextureAddConstant!
    var source: MTLTexture!
    var destination: MTLTexture!

    // MARK: - Setup

    override func setUpWithError() throws {
        self.context = try .init()
        self.euclideanDistanceFloat = try .init(context: self.context,
                                                scalarType: .float)
        self.textureAddConstantFloat = try .init(context: self.context,
                                                 scalarType: .float)
        let sourceImageFileURL = Bundle.testsResources.url(forResource: "Shared/255x121",
                                                           withExtension: "png")!
        self.source = try self.context.texture(from: .initFromURL(sourceImageFileURL),
                                               usage: [.shaderRead, .shaderWrite])
        self.destination = try self.source.matchingTexture(usage: [.shaderRead, .shaderWrite])
    }

    // MARK: - Testing

    func testEuclideanDistance() throws {
        let resultBuffer = try self.context.buffer(for: Float.self,
                                                   options: .storageModeShared)
        let constant = Float(-0.1)
        let originalTextureArea = Float(self.source.width * self.source.height)
        let euclideanDistance = originalTextureArea * sqrt((pow(constant, 2)))

        try self.context.scheduleAndWait { commandBuffer in
            self.textureAddConstantFloat(source: self.source,
                                         destination: self.destination,
                                         constant: .init(-0.1, 0, 0, 0),
                                         in: commandBuffer)
            self.euclideanDistanceFloat(textureOne: self.source,
                                        textureTwo: self.destination,
                                        resultBuffer: resultBuffer,
                                        in: commandBuffer)
        }

        let result = resultBuffer.pointer(of: Float.self)!.pointee
        let diff = abs(result - euclideanDistance)

        XCTAssertLessThanOrEqual(diff, 2)
    }

}
