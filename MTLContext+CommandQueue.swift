//
//  MTLContext+CommandQueue.swift
//  Pods
//
//  Created by Eugene Bokhan on 27.11.2019.
//

import Metal

public extension MTLContext {

    func scheduleAndWait<T>(_ bufferEncodings: (MTLCommandBuffer) throws -> T) throws -> T {
        return try self.commandQueue
                       .scheduleAndWait(bufferEncodings)
    }

    func schedule(_ bufferEncodings: (MTLCommandBuffer) throws -> Void) throws {
        try self.commandQueue
                .schedule(bufferEncodings)
    }

}
