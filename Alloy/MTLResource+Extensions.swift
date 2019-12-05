//
//  MTLResource+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/02/2019.
//

import Metal

public extension MTLResource {

    var isAccessibleOnCPU: Bool {
        #if os(iOS)
        #if targetEnvironment(simulator)
        return self.storageMode == .shared
        #elseif targetEnvironment(macCatalyst)
        return self.storageMode == .managed || self.storageMode == .shared
        #else
        return self.storageMode == .shared
        #endif // targetEnvironment
        #endif // os(iOS)

        #if os(tvOS)
        return self.storageMode == .shared
        #endif // os(tvOS)

        #if os(macOS)
        return self.storageMode == .managed || self.storageMode == .shared
        #endif // os(macOS)
    }

}
