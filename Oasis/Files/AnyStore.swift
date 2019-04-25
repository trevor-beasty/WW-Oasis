//
//  AnyStore.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public class AnyStore<Store: StoreProtocol>: StoreProtocol {
    public typealias State = Store.State
    public typealias Action = Store.Action
    public typealias Output = Store.Output
    
    public typealias R = State
    
    private let store: Store
    
    internal init(_ store: Store) {
        self.store = store
    }
    
    public func handleAction(_ action: Action) {
        store.handleAction(action)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        store.observeStatefulOutput(observer)
    }
    
    public var stateBinder: Binder<State> {
        return store.stateBinder
    }
    
}

extension StoreProtocol {
    
    func asAnyStore() -> AnyStore<Self> {
        return AnyStore<Self>(self)
    }
    
}
