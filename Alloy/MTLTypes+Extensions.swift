//
//  MTLTypes+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 08/09/2019.
//

import Metal

// MARK: - Init

extension MTLSize {
    
    public init (repeating value: Int) {
        self.init(width: value,
                  height: value,
                  depth: value)
    }

}

extension MTLOrigin {

    public init (repeating value: Int) {
        self.init(x: value,
                  y: value,
                  z: value)
    }

}

