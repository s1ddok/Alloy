//
//  MTLIndexBuffer.swift
//  Alloy
//
//  Created by Andrey Volodin on 30/04/2019.
//

import Metal

public class MTLIndexBuffer {
    public enum Errors: Error {
        case allocationFailed
    }

    public let buffer: MTLBuffer
    public let count: Int
    public let type: MTLIndexType

    public init(device: MTLDevice, indexArray: [UInt16], options: MTLResourceOptions = []) throws {
        guard let allocatedBuffer = device.makeBuffer(bytes: indexArray,
                                                      length: indexArray.count * MemoryLayout<UInt16>.stride,
                                                      options: options)
        else { throw Errors.allocationFailed }

        self.buffer = allocatedBuffer
        self.count = indexArray.count
        self.type = .uint16
    }

    public init(device: MTLDevice, indexArray: [UInt32], options: MTLResourceOptions = []) throws {
        guard let allocatedBuffer = device.makeBuffer(bytes: indexArray,
                                                      length: indexArray.count * MemoryLayout<UInt32>.stride,
                                                      options: options)
        else { throw Errors.allocationFailed }

        self.buffer = allocatedBuffer
        self.count = indexArray.count
        self.type = .uint32
    }
}
