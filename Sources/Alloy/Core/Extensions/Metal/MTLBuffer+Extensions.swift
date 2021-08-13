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

    /// Put a value in `MTLBuffer` at desired offset.
    /// - Parameters:
    ///   - value: value to put in the buffer.
    ///   - offset: offset in bytes.
    func put<T>(_ value: T,
                at offset: Int = 0) throws {
        guard self.length - offset >= MemoryLayout<T>.stride
        else { throw MetalError.MTLBufferError.incompatibleData }
        (self.contents() + offset).assumingMemoryBound(to: T.self)
                                  .pointee = value
    }

    /// Put values in `MTLBuffer` at desired offset.
    /// - Parameters:
    ///   - values: values to put in the buffer.
    ///   - offset: offset in bytes.
    func put<T>(_ values: [T],
                at offset: Int = 0) throws {
        let dataLength = MemoryLayout<T>.stride * values.count
        guard self.length - offset >= dataLength
        else { throw MetalError.MTLBufferError.incompatibleData }
        (self.contents() + offset).copyMemory(from: values,
                                              byteCount: MemoryLayout<T>.stride * values.count)
    }
}
