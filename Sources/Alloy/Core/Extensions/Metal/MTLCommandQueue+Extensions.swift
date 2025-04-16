import Metal

public extension MTLCommandQueue {

    @available(iOS 13.0, macOS 12.0, *)
    func schedule<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) async throws -> T {
        guard let commandBuffer = self.makeCommandBuffer()
        else { throw MetalError.MTLCommandQueueError.commandBufferCreationFailed }

        let retVal = try bufferEncodings(commandBuffer)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return retVal
    }
    
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
