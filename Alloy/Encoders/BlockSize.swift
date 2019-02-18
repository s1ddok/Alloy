//
//  BlockSize.swift
//  Alloy
//
//  Created by Eugene Bokhan on 14/02/2019.
//

import Foundation

public struct BlockSize {
    public var width: UInt16
    public var height: UInt16

    public init(width: UInt16, height: UInt16) {
        self.width = width
        self.height = height
    }
}
