//
//  MTLTypes+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 08/09/2019.
//

import Metal

public extension MTLSize {
    
    public init(repeating value: Int) {
        self.init(width: value,
                  height: value,
                  depth: value)
    }

    public static let one = MTLSize(repeating: 1)

}

public extension MTLOrigin {

    public init(repeating value: Int) {
        self.init(x: value,
                  y: value,
                  z: value)
    }

    public static let one = MTLOrigin(repeating: 1)

}

