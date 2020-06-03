import Foundation
import Accelerate

/// Typealias of UInt16 for dealing with 16-bit floating point values in Swift.
///
/// Since Swift has no datatype for a 16-bit float we use UInt16s instead, which
/// take up the same amount of memory. (Note: The simd framework does have "half"
/// types but only for 2, 3, or 4-element vectors, not scalars.)
public typealias Float16 = UInt16

/// Uses vImage to convert a buffer of float16 values to regular Swift Floats.
///
/// - Parameters:
///   - input: A pointer to an array of `Float16`s.
///   - count: Number of elements in the array.
/// - Returns: An array of regular Swift `Float`s.
public func float16to32(_ input: UnsafeMutableRawPointer, count: Int) -> [Float]? {
    var output = [Float](repeating: 0, count: count)
    var bufferFloat16 = vImage_Buffer(data: input, height: 1, width: UInt(count), rowBytes: count * 2)
    var bufferFloat32 = vImage_Buffer(data: &output, height: 1, width: UInt(count), rowBytes: count * 4)

    if vImageConvert_Planar16FtoPlanarF(&bufferFloat16, &bufferFloat32, 0) != kvImageNoError {
        return nil
    }
    return output
}

/// Uses vImage to convert an array of Swift floats into a buffer of float16s.
///
/// - Parameters:
///   - input: A pointer to an array of `Float`s.
///   - count: Number of elements in the array.
/// - Returns: An array of `Float16`s.
public func float32to16(_ input: UnsafeMutablePointer<Float>, count: Int) -> [Float16]? {
    var output = [Float16](repeating: 0, count: count)
    var bufferFloat32 = vImage_Buffer(data: input, height: 1, width: UInt(count), rowBytes: count * 4)
    var bufferFloat16 = vImage_Buffer(data: &output, height: 1, width: UInt(count), rowBytes: count * 2)

    if vImageConvert_PlanarFtoPlanar16F(&bufferFloat32, &bufferFloat16, 0) != kvImageNoError {
        return nil
    }
    return output
}
