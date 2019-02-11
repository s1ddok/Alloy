//
//  MPSImage+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 07/02/2019.
//  Copyright © 2019 Eugene Bokhan. All rights reserved.
//

import MetalPerformanceShaders

/* Utility functions for converting of MPSImages to floating point arrays. */

public extension MPSImage {

    /// Utility function for converting of MPSImages to floating point arrays.
    ///
    /// - Returns: Array of floats containing each pixel of MPSImage's texture.
    func toFloatArray() -> [Float]? {
        switch pixelFormat {
        case .r16Float, .rg16Float, .rgba16Float: return fromFloat16()
        case .r32Float, .rg32Float, .rgba32Float: return fromFloat32()
        default: return nil
        }
    }

    private func fromFloat16() -> [Float]? {
        guard
            var outputFloat16 = convert(initial: Float16(0))
        else { return nil }
        return float16to32(&outputFloat16, count: outputFloat16.count)
    }

    private func fromFloat32() -> [Float]? {
        return convert(initial: Float(0))
    }

    private func convert<T>(initial: T) -> [T]? {
        #if os(iOS) || os(tvOS)
        guard self.texture.storageMode == .shared else { return nil }
        #elseif os(macOS)
        guard self.texture.storageMode == .shared || self.texture.storageMode == .managed else { return nil }
        #endif

        let numSlices = (featureChannels + 3) / 4

        /// If the number of channels is not a multiple of 4, we may need to add
        /// padding. For 1 and 2 channels we don't need padding.
        let channelsPlusPadding = (featureChannels < 3) ? featureChannels : numSlices * 4

        /// How many elements we need to copy over from each pixel in a slice.
        /// For 1 channel it's just 1 element (R); for 2 channels it is 2 elements
        /// (R+G), and for any other number of channels it is 4 elements (RGBA).
        let numComponents = (featureChannels < 3) ? featureChannels : 4

        /// Allocate the memory for the array. If batching is used, then we need to
        /// copy numSlices slices for each image in the batch.
        let count = width * height * channelsPlusPadding * numberOfImages
        var output = [T](repeating: initial, count: count)

        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: width, height: height, depth: 1))

        for i in 0 ..< numSlices * numberOfImages {
            texture.getBytes(&(output[width * height * numComponents * i]),
                             bytesPerRow: width * numComponents * MemoryLayout<T>.size,
                             bytesPerImage: 0,
                             from: region,
                             mipmapLevel: 0,
                             slice: i)
        }
        return output
    }
}
