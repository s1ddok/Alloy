import Foundation

public extension Array {
    
    init(from data: Data) {
        guard data.count % MemoryLayout<Element>.stride == 0 else {
            fatalError("Cannot construct array from data as the number of bytes is not divisible by element size")
        }
        
        let numberOfElements = data.count / MemoryLayout<Element>.stride
        
        self.init(unsafeUninitializedCapacity: numberOfElements) { buffer, initializedCount in
            initializedCount = numberOfElements
            _ = data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
                memcpy(buffer.baseAddress, p.baseAddress, data.count)
            }
        }
    }
    
    var data: Data {
        return self.withUnsafeBufferPointer { pointer in
            return Data(buffer: pointer)
        }
    }
}
