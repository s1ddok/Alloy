//
//  EuclideanDistanceTests.swift
//  Demo
//
//  Created by Eugene Bokhan on 04/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import XCTest
import Alloy
import MetalKit

final class EuclideanDistanceTests: XCTestCase {

    // MARK: - Errors

    enum Errors: Error {
        case cgImageCreationFailed
        case textureCreationFailed
        case bufferCreationFailed
    }

    // MARK: - Properties

    public var context: MTLContext!
    public var euclideanDistanceFloat: EuclideanDistanceEncoder!
    public var textureAddConstantFloat: TextureAddConstantEncoder!

    // MARK: - Setup

    override func setUp() {
        do {
            self.context = .init(device: Metal.device)
            self.euclideanDistanceFloat = try .init(context: self.context,
                                                    scalarType: .float)
            self.textureAddConstantFloat = try .init(context: self.context,
                                                     scalarType: .float)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testEuclideanDistance() {
        do {
            var zeroValue = Float()
            guard let resultBuffer = self.context
                                         .device
                                         .makeBuffer(bytes: &zeroValue,
                                                     length: MemoryLayout<Float>.stride,
                                                     options: .storageModeShared)
            else { throw Errors.bufferCreationFailed }

            let image = #imageLiteral(resourceName: "255")
            guard let cgImage = image.cgImage
            else { throw Errors.cgImageCreationFailed }
            let originalTexture = try self.context
                                          .texture(from: cgImage,
                                                   usage: [.shaderRead, .shaderWrite])
            guard let modifiedTexture = originalTexture.matchingTexture()
            else { throw Errors.textureCreationFailed }

            let constant = Float(-0.1)
            let originalTextureArea = Float(originalTexture.width * originalTexture.height)
            let euclideanDistance = originalTextureArea * sqrt(4 * (pow(constant, 2)))

            try self.context.scheduleAndWait { commandBuffer in
                self.textureAddConstantFloat.encode(sourceTexture: originalTexture,
                                                    destinationTexture: modifiedTexture,
                                                    constant: .init(-0.1),
                                                    in: commandBuffer)

                self.euclideanDistanceFloat.encode(textureOne: originalTexture,
                                                   textureTwo: modifiedTexture,
                                                   resultBuffer: resultBuffer,
                                                   in: commandBuffer)
            }

            let result = resultBuffer.pointer(of: Float.self)!.pointee
            let diff = abs(result - euclideanDistance)

            XCTAssert(diff < 40)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
