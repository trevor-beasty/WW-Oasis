//
//  Updatable.swift
//  WWGrowth_Example
//
//  Created by Steven Grosmark on 4/15/19.
//  Copyright © 2019 Weight Watchers International. All rights reserved.
//

import Foundation

// for easily creating copies of State with updated properties
protocol Updatable {
    func updating<T>(_ kp: WritableKeyPath<Self, T>, with value: T) -> Self
    func updating<T>(_ kp: WritableKeyPath<Self, T?>, with value: T?) -> Self
}

extension Updatable {
    
    func updating<T>(_ kp: WritableKeyPath<Self, T>, with value: T) -> Self {
        var updated = self
        updated[keyPath: kp] = value
        return updated
    }
    
    func updating<T>(_ kp: WritableKeyPath<Self, T?>, with value: T?) -> Self {
        var updated = self
        updated[keyPath: kp] = value
        return updated
    }
}
