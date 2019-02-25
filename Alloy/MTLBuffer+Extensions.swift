//
//  MTLBuffer+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 18/01/2019.
//

import Metal

public extension MTLBuffer {
    func copy(to other: MTLBuffer, offset: Int = 0) {
        memcpy(other.contents() + offset, self.contents(), self.length)
    }

    func pointer<T>(of type: T.Type) -> UnsafeMutablePointer<T>? {
        guard self.isAccessibleOnCPU else { return nil }
        let bindedPointer = self.contents().assumingMemoryBound(to: type)
        return bindedPointer
    }

    func bufferPointer<T>(of type: T.Type, capacity: Int) -> UnsafeBufferPointer<T>? {
        guard let startPointer = self.pointer(of: type) else { return nil }
        let bufferPointer = UnsafeBufferPointer(start: startPointer,
                                                count: capacity)
        return bufferPointer
    }

    func array<T>(of type: T.Type, capacity: Int) -> [T]? {
        guard let bufferPointer = self.bufferPointer(of: type, capacity: capacity) else { return nil }
        let valueArray = Array(bufferPointer)
        return valueArray
    }
}
