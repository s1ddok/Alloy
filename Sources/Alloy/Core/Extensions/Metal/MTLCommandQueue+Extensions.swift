import Metal

public extension MTLCommandQueue {

    func scheduleAndWait<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) throws -> T {
        guard let commandBuffer = self.makeCommandBuffer()
        else { throw MetalError.MTLCommandQueueError.commandBufferCreationFailed }

        let retVal = try bufferEncodings(commandBuffer)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return retVal
    }

    func schedule(_ bufferEncodings: (MTLCommandBuffer) throws -> Void) throws {
        guard let commandBuffer = self.makeCommandBuffer()
        else { throw MetalError.MTLCommandQueueError.commandBufferCreationFailed }

        try bufferEncodings(commandBuffer)

        commandBuffer.commit()
    }

}
