//
//  MTLFunctionConstantValues+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 08/09/2019.
//

import Metal

public extension MTLFunctionConstantValues {

    public func setConstantValue<T>(_ value: T,
                                    type: MTLDataType,
                                    index: Int) {
        var t = value
        self.setConstantValue(&t,
                              type: type,
                              index: index)
    }

    public func setConstantValues<T>(_ values: [T],
                                     type: MTLDataType,
                                     range: Range<Int>) {
        var t = values
        self.setConstantValues(&t,
                               type: type,
                               range: range)
    }

}
