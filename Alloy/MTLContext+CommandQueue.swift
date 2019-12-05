//
//  MTLContext+CommandQueue.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.11.2019.
//

import Metal

public extension MTLContext {

    // MARK: - Alloy API

    func scheduleAndWait<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) throws -> T {
        return try self.commandQueue
                       .scheduleAndWait(bufferEncodings)
    }

    func schedule(_ bufferEncodings: (MTLCommandBuffer) throws -> Void) throws {
        try self.commandQueue
                .schedule(bufferEncodings)
    }

    // MARK: - Vanilla API

    var commandQueueLabel: String? {
        get { self.commandQueue.label }
        set { self.commandQueue.label = newValue }
    }

    func commandBuffer() -> MTLCommandBuffer? {
        return self.commandQueue
                   .makeCommandBuffer()
    }

    func commandBufferWithUnretainedReferences() -> MTLCommandBuffer? {
        return self.commandQueue
                   .makeCommandBufferWithUnretainedReferences()
    }

}
