//
//  StateBinding.swift
//  WWFoundation
//
//  Created by Steven Grosmark on 4/3/19.
//  Iteration by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Weight Watchers International. All rights reserved.
//

import Foundation

public typealias ChangeHandler<T> = (_ oldValue: T?, _ newValue: T) -> Void

public final class Binder<Value> {
    
    internal private(set) var value: Value
    
    internal var observations: [ChangeHandler<Value>] = []
    
    internal init(_ value: Value) {
        self.value = value
    }
    
    internal func update(with newValue: Value) {
        set(newValue: newValue)
    }
    
    private func set(newValue: Value) {
        let oldValue = value
        value = newValue
        let _observations = observations
        DispatchQueue.main.async {
            _observations.forEach({ $0(oldValue, newValue) })
        }
    }
}

public protocol StateBindable: AnyObject {
    associatedtype State
    associatedtype R
    
    var stateBinder: Binder<State> { get }
    var transform: (State) -> R { get }
}

extension StateBindable {
    
    public func bind(_ handler: @escaping ChangeHandler<R>) {
        handler(nil, transform(stateBinder.value))
        let _transform = transform
        stateBinder.observations.append({ oldValue, newValue in
            handler(oldValue.flatMap({ _transform($0) }), _transform(newValue))
        })
    }
    
    public func bind<Property>(_ keyPath: KeyPath<R, Property>, to handler: @escaping ChangeHandler<Property>) {
        bind { oldValue, value in
            let oldKeyValue = oldValue.flatMap({ $0[keyPath: keyPath] })
            let newKeyValue = value[keyPath: keyPath]
            handler(oldKeyValue, newKeyValue)
        }
    }
    
    public func bind<Property>(_ keyPath: KeyPath<R, Property>, to handler: @escaping ChangeHandler<Property>) where Property: Equatable {
        bind { oldValue, value in
            let oldKeyValue = oldValue.flatMap({ $0[keyPath: keyPath] })
            let newKeyValue = value[keyPath: keyPath]
            guard oldKeyValue != newKeyValue else { return }
            handler(oldKeyValue, newKeyValue)
        }
    }
    
}

extension StateBindable where R: Equatable {
    
    public func bind(_ handler: @escaping ChangeHandler<R>) {
        handler(nil, transform(stateBinder.value))
        let _transform = transform
        stateBinder.observations.append({ oldValue, newValue in
            guard oldValue.flatMap({ _transform($0) }) != _transform(newValue) else { return }
            handler(oldValue.flatMap({ _transform($0) }), _transform(newValue))
        })
    }
    
}

extension StateBindable where State == R {
    
    public var transform: (State) -> R {
        return { state in return state }
    }
    
}
