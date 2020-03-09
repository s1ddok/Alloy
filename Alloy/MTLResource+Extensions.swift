//
//  MTLResource+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/02/2019.
//

import Metal

public extension MTLResource {

    var isAccessibleOnCPU: Bool {
        #if (os(iOS) && !targetEnvironment(macCatalyst)) || os(tvOS)
        return self.storageMode == .shared
        #elseif os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        return self.storageMode == .managed || self.storageMode == .shared
        #endif
    }

}
