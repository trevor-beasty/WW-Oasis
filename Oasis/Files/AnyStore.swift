//
//  AnyStore.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public class AnyStore<State, Action, Output>: StoreType {
    public typealias R = State
    
    private let _handleAction: (Action) -> Void
    private let _observeStatefulOutput: (@escaping (Output, State) -> Void) -> Void
    public let binder: IndirectBinder<State>
    public let objectBinder: ObjectBinder
    
    internal init<Store: StoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self._handleAction = store.handleAction
        self._observeStatefulOutput = store.observeStatefulOutput
        self.binder = IndirectBinder(store.binder)
        self.objectBinder = store.objectBinder
    }
    
    public func handleAction(_ action: Action) {
        _handleAction(action)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        _observeStatefulOutput(observer)
    }
    
}

extension StoreType {
    
    func asAnyStore() -> AnyStore<State, Action, Output> {
        return AnyStore<State, Action, Output>.init(self)
    }
    
}
