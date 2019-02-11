//
//  Sequence+Utils.swift
//  AlloyDemo
//
//  Created by Andrey Volodin on 29.08.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

extension Sequence {
    public func toDictionary<Key: Hashable>(with selectKey: (Iterator.Element) -> Key) -> [Key: Iterator.Element] {
        var dict: [Key: Iterator.Element] = [:]
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
