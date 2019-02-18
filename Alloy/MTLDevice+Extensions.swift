//
//  MTLDevice+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 18/02/2019.
//

import Metal
import MetalKit

public enum MTLFeatures {
    case nonUniformThreadgroupSize
}

private let gpuFamiliesForFeatures: [MTLFeatures : Set<MTLFeatureSet>] = {
    var gpuFamiliesForFeatures: [MTLFeatures : Set<MTLFeatureSet>] = [:]

    // MARK: - NonUniformThreadgroupSize

    #if os(iOS)
    gpuFamiliesForFeatures[.nonUniformThreadgroupSize] = [
        .iOS_GPUFamily4_v1,
    ]
    if #available(iOS 12.0, *) {
        let iOS12GPUFamilies: Set<MTLFeatureSet> = [
            .iOS_GPUFamily4_v2,
            .iOS_GPUFamily5_v1
        ]
        gpuFamiliesForFeatures[.nonUniformThreadgroupSize] =
            gpuFamiliesForFeatures[.nonUniformThreadgroupSize]!.union(iOS12GPUFamilies)
    }
    #elseif os(tvOS)
    gpuFamiliesForFeatures[.nonUniformThreadgroupSize] = []
    #elseif os(macOS)
    gpuFamiliesForFeatures[.nonUniformThreadgroupSize] = [
        .macOS_GPUFamily1_v3,
        .macOS_GPUFamily1_v4,
        .macOS_GPUFamily2_v1
    ]
    #endif

    return gpuFamiliesForFeatures
}()

public extension MTLDevice {

    func deviceSupportsFeature(_ feature: MTLFeatures) -> Bool {
        guard let gpuFamilies = gpuFamiliesForFeatures[feature]
        else { return false }
        return deviceSupportsFeature(from: gpuFamilies)
    }

    private func deviceSupportsFeature(from featureSet: Set<MTLFeatureSet>) -> Bool {
        let result = featureSet.map { (mtlFeatureSet) -> Bool in
            self.supportsFeatureSet(mtlFeatureSet)
            }.contains(true)
        return result
    }

}
