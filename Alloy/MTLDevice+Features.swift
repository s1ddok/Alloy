//
//  MTLDevice+FeatureSet.swift
//  Alloy
//
//  Created by Andrey Volodin on 26/04/2019.
//

import Metal

public enum Feature {
    case nonUniformThreadgroups
}

public extension MTLDevice {
    func supports(feature: Feature) -> Bool {
        switch feature {
        case .nonUniformThreadgroups:
            #if targetEnvironment(UIKitForMac)
            return self.supportsFamily(.familyCommon3)
            #elseif os(iOS)
            return self.supportsFeatureSet(.iOS_GPUFamily4_v1)
            #elseif os(macOS)
            return self.supportsFeatureSet(.macOS_GPUFamily1_v3)
            #endif
        }
    }
}
