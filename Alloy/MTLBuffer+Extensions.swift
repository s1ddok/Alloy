//
//  MTLBuffer+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 18/01/2019.
//

import Metal

public extension MTLBuffer {
    func copy(to other: MTLBuffer,
              offset: Int = 0) {
        memcpy(other.contents() + offset,
               self.contents(),
               self.length)
    }

    func pointer<T>(of type: T.Type) -> UnsafeMutablePointer<T>? {
        guard self.isAccessibleOnCPU
        else { return nil }
        
        #if DEBUG
        guard self.length >= MemoryLayout<T>.stride
        else { fatalError("Buffer length check failed") }
        #endif
        
        let bindedPointer = self.contents()
                                .assumingMemoryBound(to: type)
        return bindedPointer
    }

    func bufferPointer<T>(of type: T.Type,
                          count: Int) -> UnsafeBufferPointer<T>? {
        guard let startPointer = self.pointer(of: type)
        else { return nil }
        let bufferPointer = UnsafeBufferPointer(start: startPointer,
                                                count: count)
        return bufferPointer
    }

    func array<T>(of type: T.Type,
                  count: Int) -> [T]? {
        guard let bufferPointer = self.bufferPointer(of: type,
                                                     count: count)
        else { return nil }
        let valueArray = Array(bufferPointer)
        return valueArray
    }

    func fill<T>(with value: T) throws {
        guard let pointer = self.pointer(of: T.self)
        else { throw MetalError.MTLBufferError.incompatibleData }
        pointer.pointee = value
    }

    func fill<T>(with values: [T]) throws {
        var values = values
        let dataLength = MemoryLayout<T>.stride * values.count
        guard self.length >= dataLength
        else { throw MetalError.MTLBufferError.incompatibleData }

        memcpy(&values,
               self.contents(),
               dataLength)
    }
}
