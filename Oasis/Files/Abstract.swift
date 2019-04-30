//
//  Abstract.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

internal func lassoAbstractMethod<T>(line: UInt = #line, file: StaticString = #file) -> T {
    fatalError("abstract method must be overriden by subclass", file: file, line: line)
}

public enum None { }

public final class WeakBox<T: AnyObject> {
    
    weak var boxed: T?
    
    init(_ boxed: T?) {
        self.boxed = boxed
    }
    
}

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public typealias Update<T> = (inout T) -> Void

extension WeakBox {
    
    internal func map<R: AnyObject>(_ transform: (T) -> R) -> WeakBox<R> {
        let result: R?
        if let boxed = boxed { result = transform(boxed) }
        else { result = nil}
        return WeakBox<R>(result)
    }
    
}

internal enum WeakStrong<T: AnyObject> {
    case strong(T)
    case weak(WeakBox<T>)
}

internal func executeOnMainThread(_ toExecute: @escaping () -> Void) {
    if Thread.isMainThread {
        toExecute()
    }
    else {
        DispatchQueue.main.async {
            toExecute()
        }
    }
}
