//
//  MTLPixelFormat+ScalarType.swift
//  Alloy
//
//  Created by Eugene Bokhan on 03/09/2019.
//

import Metal

public extension MTLPixelFormat {
    enum ScalarType: String {
        case float, half, ushort, short, uint, int
    }
}
