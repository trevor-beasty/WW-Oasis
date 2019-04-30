//
//  Store.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

public protocol StoreDefinition: ModuleDefinition {
    associatedtype State
    
    typealias Store = AnyStore<State, Action, Output>
}

public protocol AbstractStoreType: BinderHostType, ObjectBindable where BindableValue == State {
    associatedtype State
    associatedtype Action
    associatedtype Output
    
    func handleAction(_ action: Action)
    func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void)
}

public protocol StoreType: AbstractStoreType {
    init(_ initialState: State)
}

open class Store<Definition: StoreDefinition>: Module<Definition.Action, Definition.Output>, StoreType {
    public typealias State = Definition.State
    public typealias Action = Definition.Action
    public typealias Output = Definition.Output
    
    private let sourceBinder: SourceBinder<State>
    public let objectBinder = ObjectBinder()
    
    private var pendingUpdates: [Update<State>] = []
    
    public required init(_ initialState: State) {
        self.sourceBinder = SourceBinder(initialState)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        observeOutput({ [weak self] output in
            guard let strongSelf = self else { return }
            observer(output, strongSelf.sourceBinder.value)
        })
    }
    
    public func update(_ update: @escaping Update<State> = { _ in return }) {
        pendingUpdates.append(update)
        applyUpdates()
    }
    
    public func batchUpdate(_ update: @escaping Update<State>) {
        pendingUpdates.append(update)
    }
    
    private func applyUpdates() {
        let updated = pendingUpdates.reduce(sourceBinder.value) { (lastState, nextUpdate) -> State in
            var copy = lastState
            nextUpdate(&copy)
            return copy
        }
        sourceBinder.set(newValue: updated)
        pendingUpdates = []
    }
    
    public var binder: AnyBinder<State> {
        return sourceBinder.asBinder()
    }
    
}

extension AbstractStoreType {
    
    public var state: State {
        return binder.value
    }
    
}
