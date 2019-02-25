//
//  MTLResource+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/02/2019.
//

import Metal

public extension MTLResource {

    var isAccessibleOnCPU: Bool {
        #if os(iOS) || os(tvOS) || os(watchOS)
        return self.storageMode == .shared
        #elseif os(OSX)
        return self.storageMode == .managed
        #endif
    }

}
