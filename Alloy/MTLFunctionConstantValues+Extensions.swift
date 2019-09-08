//
//  MTLFunctionConstantValues+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 08/09/2019.
//

import Metal

public extension MTLFunctionConstantValues {

    // MARK: - Bool

    func set(_ value: Bool,
             index: Int) {
        var t = value
        self.setConstantValue(&t,
                              type: .bool,
                              index: index)
    }

    func set(_ values: [Bool],
             range: Range<Int>) {
        self.setConstantValues(values,
                               type: .bool,
                               range: range)
    }

    // MARK: - Float

    func set(_ value: Float,
             index: Int) {
        var t = value
        self.setConstantValue(&t,
                              type: .float,
                              index: index)
    }

    func set(_ values: [Float],
             range: Range<Int>) {
        self.setConstantValues(values,
                               type: .float,
                               range: range)
    }

}
