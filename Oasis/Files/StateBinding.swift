//
//  StateBinding.swift
//  WWFoundation
//
//  Created by Steven Grosmark on 4/3/19.
//  Iteration by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Weight Watchers International. All rights reserved.
//

import Foundation

public typealias Observer<T> = (_ oldValue: T?, _ newValue: T) -> Void

public protocol BinderType: AnyObject {
    associatedtype Value
    
    var value: Value { get }
    func observe(_ observer: @escaping Observer<Value>)
}

public class AnyBinder<Value>: BinderType {
    
    private let _value: () -> Value
    private let _observe: (@escaping Observer<Value>) -> Void
    
    internal init<Binder: BinderType>(_ binder: Binder) where Binder.Value == Value {
        self._value = { return binder.value }
        self._observe = binder.observe
    }
    
    public var value: Value {
        return _value()
    }
    
    public func observe(_ observer: @escaping (Value?, Value) -> Void) {
        _observe(observer)
    }
    
}

extension BinderType {
    
    func asBinder() -> AnyBinder<Value> {
        return AnyBinder<Value>(self)
    }
    
}

public final class SourceBinder<Value>: BinderType {
    
    public private(set) var value: Value
    private var observers: [Observer<Value>] = []
    
    internal init(_ value: Value) {
        self.value = value
    }
    
    internal func set(newValue: Value) {
        let oldValue = value
        value = newValue
        executeOnMainThread { [weak self] in
            /// Dispatch to all observers which exist at execution time - it is possible that additional
            /// observers could be added b/w queuing and execution.
            self?.observers.forEach({ $0(oldValue, newValue) })
        }
    }
    
    public func observe(_ observer: @escaping Observer<Value>) {
        observers.append(observer)
    }
    
}

public final class IndirectBinder<Value>: BinderType {
    
    private let _observe: (@escaping Observer<Value>) -> Void
    private let _value: () -> Value
    
    internal init<SourceBinder: BinderType>(_ sourceBinder: SourceBinder, _ transform: @escaping (SourceBinder.Value) -> Value) {
        
        _observe = { observer in
            sourceBinder.observe({ s0, s1 in
                let v0: Value?
                if let s0 = s0 {
                    v0 = transform(s0)
                }
                else {
                    v0 = nil
                }
                let v1 = transform(s1)
                observer(v0, v1)
            })
        }
        
        _value = {
            return transform(sourceBinder.value)
        }
        
    }
    
    internal convenience init<SourceBinder: BinderType>(_ sourceBinder: SourceBinder) where SourceBinder.Value == Value {
        self.init(sourceBinder, { $0 })
    }
    
    public var value: Value {
        return _value()
    }
    
    public func observe(_ observer: @escaping (Value?, Value) -> Void) {
        _observe(observer)
    }
    
}

public protocol BinderHostType: AnyObject {
    associatedtype BindableValue
    
    var binder: AnyBinder<BindableValue> { get }
}

extension BinderHostType {
    
    public func bind(_ handler: @escaping Observer<BindableValue>) {
        handler(nil, binder.value)
        binder.observe(handler)
    }
    
    public func bind<Property>(_ keyPath: KeyPath<BindableValue, Property>, to handler: @escaping Observer<Property>) {
        bind { oldValue, value in
            let oldKeyValue = oldValue.flatMap({ $0[keyPath: keyPath] })
            let newKeyValue = value[keyPath: keyPath]
            handler(oldKeyValue, newKeyValue)
        }
    }
    
    public func bind<Property>(_ keyPath: KeyPath<BindableValue, Property>, to handler: @escaping Observer<Property>) where Property: Equatable {
        bind { oldValue, value in
            let oldKeyValue = oldValue.flatMap({ $0[keyPath: keyPath] })
            let newKeyValue = value[keyPath: keyPath]
            guard oldKeyValue != newKeyValue else { return }
            handler(oldKeyValue, newKeyValue)
        }
    }
    
}

extension BinderHostType where BindableValue: Equatable {
    
    public func bind(_ handler: @escaping Observer<BindableValue>) {
        handler(nil, binder.value)
        let _observer: Observer<BindableValue> = { oldValue, newValue in
            if let oldValue = oldValue, oldValue == newValue { return  }
            handler(oldValue, newValue)
        }
        binder.observe(_observer)
    }
    
}
