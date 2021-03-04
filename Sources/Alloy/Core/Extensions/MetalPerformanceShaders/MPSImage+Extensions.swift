import MetalPerformanceShaders

/* Utility functions for converting of MPSImages to floating point arrays. */
public extension MPSImage {

    /// Utility function for converting of MPSImages to floating point arrays.
    ///
    /// - Returns: Array of floats containing each pixel of MPSImage's texture.
    func toFloatArray() -> [Float]? {
        switch self.pixelFormat {
        case .r16Float, .rg16Float, .rgba16Float:
            if #available(iOS 14.0, macOS 11.0, macCatalyst 14.5, *),
               let float16Array: [Swift.Float16] = self.toArray() {
                return float16Array.map(Float.init)
            } else if var float16Array: [Float16] = self.toArray() {
                return float16to32(&float16Array,
                                   count: float16Array.count)
            } else { return nil }
        case .r32Float, .rg32Float, .rgba32Float, .depth32Float:
            return self.toArray()
        case .invalid: return nil
        default: return nil
        }
    }

    private func toArray<T: Numeric>() -> [T]? {
        guard self.texture.isAccessibleOnCPU
        else { return nil }

        let numSlices = (self.featureChannels + 3) / 4

        /// If the number of channels is not a multiple of 4, we may need to add
        /// padding. For 1 and 2 channels we don't need padding.
        let channelsPlusPadding = (self.featureChannels < 3)
                                ? self.featureChannels
                                : numSlices * 4

        /// How many elements we need to copy over from each pixel in a slice.
        /// For 1 channel it's just 1 element (R); for 2 channels it is 2 elements
        /// (R+G), and for any other number of channels it is 4 elements (RGBA).
        let numComponents = (self.featureChannels < 3)
                          ? self.featureChannels
                          : 4

        /// Allocate the memory for the array. If batching is used, then we need to
        /// copy numSlices slices for each image in the batch.
        let count = self.width
                  * self.height
                  * channelsPlusPadding
                  * self.numberOfImages

        var output = [T](repeating: .zero,
                         count: count)

        let region = MTLRegion(origin: .zero,
                               size: .init(width: self.width,
                                           height: self.height,
                                           depth: 1))

        for i in 0 ..< numSlices * self.numberOfImages {
            self.texture.getBytes(&(output[self.width * self.height * numComponents * i]),
                                  bytesPerRow: self.width * numComponents * MemoryLayout<T>.self.size,
                                  bytesPerImage: 0,
                                  from: region,
                                  mipmapLevel: 0,
                                  slice: i)
        }

        return output
    }
}
