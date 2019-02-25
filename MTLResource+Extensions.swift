//
//  MTLResource+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 25/02/2019.
//

import Metal

public extension MTLResource {

    var isAccessibleOnCPU: Bool {
        #if os(iOS) || os(tvOS)
        return self.storageMode == .shared
        #elseif os(macOS)
        return self.storageMode == .managed
        #endif
    }

}
