//
//  MTLCommandQueue+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.11.2019.
//

import Metal

public extension MTLCommandQueue {

    func scheduleAndWait<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) throws -> T {
        guard let commandBuffer = self.makeCommandBuffer()
        else { throw MetalError.commandQueue(.commandBufferCreationFailed) }

        let retVal = try bufferEncodings(commandBuffer)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return retVal
    }

    func schedule(_ bufferEncodings: (MTLCommandBuffer) throws -> Void) throws {
        guard let commandBuffer = self.makeCommandBuffer()
        else { throw MetalError.commandQueue(.commandBufferCreationFailed) }

        try bufferEncodings(commandBuffer)

        commandBuffer.commit()
    }

}
