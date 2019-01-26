//
//  MTLBuffer+Extensions.swift
//  Alloy
//
//  Created by Andrey Volodin on 18/01/2019.
//

import Metal

public extension MTLBuffer {
    func copy(to other: MTLBuffer, offset: Int = 0) {
        memcpy(other.contents() + offset, self.contents(), self.length)
    }
}
