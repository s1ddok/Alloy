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
            #if os(iOS)
            if #available(iOS 11.0, *) {
                return self.supportsFeatureSet(.iOS_GPUFamily4_v1)
            } else {
                return false
            }
            #elseif os(macOS)
            if #available(OSX 10.13, *) {
                return self.supportsFeatureSet(.macOS_GPUFamily1_v3)
            } else {
                return false
            }
            #endif
        }
    }
}
