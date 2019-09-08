//
//  MTLFunctionConstantValues+Extensions.swift
//  Alloy
//
//  Created by Eugene Bokhan on 08/09/2019.
//

import Metal

public extension MTLFunctionConstantValues {

    // MARK: - Generic

    func set<T>(_ value: T,
                type: MTLDataType,
                at index: Int) {
        var t = value
        self.setConstantValue(&t,
                              type: type,
                              index: index)
    }

    func set<T>(_ values: [T],
                type: MTLDataType,
                startingAt startIndex: Int = 0) {
        self.setConstantValues(values,
                               type: type,
                               range: startIndex ..< (startIndex + values.count))
    }

    // MARK: - Bool

    func set(_ value: Bool,
             at index: Int) {
        self.set(value,
                 type: .bool,
                 at: index)
    }

    func set(_ values: [Bool],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .bool,
                 startingAt: startIndex)
    }

    // MARK: - Float

    func set(_ value: Float,
             at index: Int) {
        self.set(value,
                 type: .float,
                 at: index)
    }

    func set(_ values: [Float],
             startingAt startIndex: Int = 0) {
        self.set(values,
                 type: .float,
                 startingAt: startIndex)
    }

}
