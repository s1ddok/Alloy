import Metal

public extension MTLIndexType {
    var stride: Int {
        switch self {
        case .uint16: return MemoryLayout<UInt16>.stride
        case .uint32: return MemoryLayout<UInt32>.stride
        @unknown default:
            fatalError()
        }
    }
}

public class MTLIndexBuffer {

    public let buffer: MTLBuffer
    public let count: Int
    public let type: MTLIndexType

    public init(device: MTLDevice,
                count: Int,
                type: MTLIndexType,
                options: MTLResourceOptions = .cpuCacheModeWriteCombined) throws {
        guard let allocatedBuffer = device.makeBuffer(length: count * type.stride, options: options)
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
    
    public func pointer<T>(of type: T.Type) -> UnsafeMutablePointer<T>? {
        return self.buffer.pointer(of: T.self)
    }
    
    public func bufferPointer<T>(of type: T.Type,
                          count: Int) -> UnsafeBufferPointer<T>? {
        return self.buffer.bufferPointer(of: T.self, count: count)
    }

    public func array<T>(of type: T.Type,
                  count: Int) -> [T]? {
        return self.buffer.array(of: T.self, count: count)
    }
    
    public subscript(index: Int) -> UInt16 {
        get {
            #if DEBUG
            if self.type != .uint16 {
                assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
            }
            #endif
            return self.buffer.pointer(of: UInt16.self)![index]
        }
        set {
            #if DEBUG
            if self.type != .uint16 {
                assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
            }
            #endif
            self.buffer.pointer(of: UInt16.self)![index] = newValue
        }
    }
    
    public subscript(index: Int) -> UInt32 {
        get {
            #if DEBUG
            if self.type != .uint32 {
                assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
            }
            #endif
            return self.buffer.pointer(of: UInt32.self)![index]
        }
        set {
            #if DEBUG
            if self.type != .uint32 {
                assertionFailure("WARNING: Trying to insert UInt16 index into different type index buffer")
            }
            #endif
            self.buffer.pointer(of: UInt32.self)![index] = newValue
        }
    }
}
