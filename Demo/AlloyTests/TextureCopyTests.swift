//
//  TextureCopyTests.swift
//  Alloy
//
//  Created by Eugene Bokhan on 10.12.2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import XCTest
import Alloy

final class TextureCopyTests: XCTestCase {

    struct TestCase {
        let sourceRegion: MTLRegion
        let destinationOrigin: MTLOrigin
        let sourceTexture: MTLTexture
        let destinationTexture: MTLTexture
        let desiredResultTexture: MTLTexture

        init(context: MTLContext,
             sourceRegion: MTLRegion,
             destinationOrigin: MTLOrigin,
             sourceImage: CGImage,
             destinationImage: CGImage,
             desiredResultImage: CGImage) throws {
            self.sourceRegion = sourceRegion
            self.destinationOrigin = destinationOrigin
            try self.sourceTexture = context.texture(from: sourceImage,
                                                     usage: [.shaderRead, .shaderWrite])
            try self.destinationTexture = context.texture(from: destinationImage,
                                                          usage: [.shaderRead, .shaderWrite])
            try self.desiredResultTexture = context.texture(from: desiredResultImage,
                                                            usage: [.shaderRead, .shaderWrite])
        }
    }

    // MARK: - Properties

    public var context = MTLContext()
    public var euclideanDistanceFloat: EuclideanDistanceEncoder!
    public var textureCopyEncoder: TextureCopyEncoder!
    public var testCases: [TestCase]!

    // MARK: - Setup

    override func setUp() {
        do {
            self.euclideanDistanceFloat = try .init(context: self.context,
                                                    scalarType: .float)
            self.textureCopyEncoder = try .init(context: self.context,
                                                scalarType: .float)

            let bundle = Bundle(for: Self.self)
            let jsonDecoder = JSONDecoder()
            let testCasesFolderURL = bundle.url(forResource: Self.testCasesFolderName,
                                                withExtension: nil)!

            self.testCases = try [0, 1, 2, 3].map { i -> TextureCopyTests.TestCase in
                let sourceRegionFileURL = testCasesFolderURL.appendingPathComponent("/\(i)/\(Self.sourceRegionFileName)")
                let destinationOriginFileURL = testCasesFolderURL.appendingPathComponent("/\(i)/\(Self.destinationOriginFileName)")
                let sourceImageFileURL = testCasesFolderURL.appendingPathComponent("/\(i)/\(Self.sourceImageFileName)")
                let destinationImageFileURL = testCasesFolderURL.appendingPathComponent("/\(i)/\(Self.destinationImageFileName)")
                let desiredResultImageFileURL = testCasesFolderURL.appendingPathComponent("/\(i)/\(Self.desiredResultImageFileName)")

                let sourceRegionData = try Data(contentsOf: sourceRegionFileURL)
                let destinationOriginData = try Data(contentsOf: destinationOriginFileURL)
                let sourceImageData = try Data(contentsOf: sourceImageFileURL)
                let destinationImageData = try Data(contentsOf: destinationImageFileURL)
                let desiredResultImageData = try Data(contentsOf: desiredResultImageFileURL)

                return try TestCase(context: self.context,
                                    sourceRegion: jsonDecoder.decode(MTLRegion.self,
                                                                     from: sourceRegionData),
                                    destinationOrigin: jsonDecoder.decode(MTLOrigin.self,
                                                                          from: destinationOriginData),
                                    sourceImage: UIImage(data: sourceImageData)!.cgImage!,
                                    destinationImage: UIImage(data: destinationImageData)!.cgImage!,
                                    desiredResultImage: UIImage(data: desiredResultImageData)!.cgImage!)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testTextureCopy() {
        do {
            // Setup results buffer.
            guard let resultBuffer = self.context
                                         .buffer(for: Float.self,
                                                 options: .storageModeShared)
            else { throw MetalError.MTLBufferError.allocationFailed }

            // Dispatch.
            try self.testCases.forEach { testCase in
                try self.context.scheduleAndWait { commandBuffer in
                    self.textureCopyEncoder
                        .copy(region: testCase.sourceRegion,
                              from: testCase.sourceTexture,
                              to: testCase.destinationOrigin,
                              of: testCase.destinationTexture,
                              in: commandBuffer)

                    self.euclideanDistanceFloat
                        .encode(textureOne: testCase.destinationTexture,
                                textureTwo: testCase.desiredResultTexture,
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

