import Metal

public class MTLIndexBuffer {

    public let buffer: MTLBuffer
    public let count: Int
    public let type: MTLIndexType

    public init(device: MTLDevice,
                count: Int,
                type: MTLIndexType,
                options: MTLResourceOptions = .cpuCacheModeWriteCombined) throws {
        let indexStride: Int
        switch type {
        case .uint16: indexStride = MemoryLayout<UInt16>.stride
        case .uint32: indexStride = MemoryLayout<UInt32>.stride
        @unknown default: throw MetalError.MTLBufferError.incompatibleData
        }
        
        guard let allocatedBuffer = device.makeBuffer(length: count * indexStride, options: options)
        else { throw MetalError.MTLDeviceError.bufferCreationFailed }

        self.buffer = allocatedBuffer
        self.count = count
        self.type = type
    }
    
    public init(device: MTLDevice,
                indexArray: [UInt16],
                options: MTLResourceOptions = []) throws {
        guard let allocatedBuffer = device.makeBuffer(bytes: indexArray,
                                                      length: indexArray.count * MemoryLayout<UInt16>.stride,
                                                      options: options)
        else { throw MetalError.MTLDeviceError.bufferCreationFailed }

        self.buffer = allocatedBuffer
        self.count = indexArray.count
        self.type = .uint16
    }

    public init(device: MTLDevice,
                indexArray: [UInt32],
                options: MTLResourceOptions = []) throws {
        guard let allocatedBuffer = device.makeBuffer(bytes: indexArray,
                                                      length: indexArray.count * MemoryLayout<UInt32>.stride,
                                                      options: options)
        else { throw MetalError.MTLDeviceError.bufferCreationFailed }

        self.buffer = allocatedBuffer
        self.count = indexArray.count
        self.type = .uint32
    }
    
    func pointer<T>(of type: T.Type) -> UnsafeMutablePointer<T>? {
        return self.buffer.pointer(of: T.self)
    }
    
    func bufferPointer<T>(of type: T.Type,
                          count: Int) -> UnsafeBufferPointer<T>? {
        return self.buffer.bufferPointer(of: T.self, count: count)
    }

    func array<T>(of type: T.Type,
                  count: Int) -> [T]? {
        return self.buffer.array(of: T.self, count: count)
    }

    /// Put a value in `MTLIndexBuffer` at desired offset.
    /// - Parameters:
    ///   - value: value to put in the buffer.
    ///   - offset: offset in bytes.
    func put(_ value: UInt16,
             at offset: Int = 0) throws {
        #if DEBUG
        if self.type != .uint16 {
            assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
        }
        #endif
        try self.buffer.put(value, at: offset)
    }

    /// Put values in `MTLIndexBuffer` at desired offset.
    /// - Parameters:
    ///   - values: values to put in the buffer.
    ///   - offset: offset in bytes.
    func put(_ values: [UInt16],
             at offset: Int = 0) throws {
        #if DEBUG
        if self.type != .uint16 {
            assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
        }
        #endif
        try self.buffer.put(values, at: offset)
    }
    
    /// Put a value in `MTLIndexBuffer` at desired offset.
    /// - Parameters:
    ///   - value: value to put in the buffer.
    ///   - offset: offset in bytes.
    func put(_ value: UInt32,
             at offset: Int = 0) throws {
        #if DEBUG
        if self.type != .uint32 {
            assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
        }
        #endif
        try self.buffer.put(value, at: offset)
    }

    /// Put values in `MTLIndexBuffer` at desired offset.
    /// - Parameters:
    ///   - values: values to put in the buffer.
    ///   - offset: offset in bytes.
    func put(_ values: [UInt32],
             at offset: Int = 0) throws {
        #if DEBUG
        if self.type != .uint32 {
            assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
        }
        #endif
        try self.buffer.put(values, at: offset)
    }
}
