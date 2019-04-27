//
//  Abstract.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

internal let abstractMethodMessage = "abstract method must be overriden by subclass"

internal func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}

public enum None { }

internal final class WeakBox<T: AnyObject> {
    
    weak var boxed: T?
    
    init(_ boxed: T) {
        self.boxed = boxed
    }
    
}
