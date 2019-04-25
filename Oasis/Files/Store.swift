//
//  Store.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

public protocol ModuleDefinition {
    associatedtype Action
    associatedtype Output
}

public protocol StoreDefinition: ModuleDefinition {
    associatedtype State
}

public protocol ViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

public protocol ModuleProtocol: ModuleDefinition {
    func handleAction(_ action: Action)
    func observeOutput(_ observer: @escaping (Output) -> Void)
}

public protocol StoreProtocol: StoreDefinition, StateBindable {
    func handleAction(_ action: Action)
    func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void)
}

open class Module<Action, Output>: ModuleProtocol {
    
    private var outputObservers: [(Output) -> Void] = []
    
    public init() { }
    
    open func handleAction(_ action: Action) {
        fatalError(abstractMethodMessage)
    }
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservers.append(observer)
    }
    
    public func output(_ output: Output) {
        emit {
            self.outputObservers.forEach({ $0(output) })
        }
    }
    
}

open class Store<Definition: StoreDefinition>: Module<Definition.Action, Definition.Output>, StoreProtocol {
    public typealias State = Definition.State
    public typealias R = State
    
    public private(set) var stateBinder: Binder<State>
    private var stateObservers: [(State) -> Void] = []
    
    public static func create(with initialState: State) -> AnyStore<Store<Definition>> {
        let store = self.init(initialState: initialState)
        return store.asAnyStore()
    }
    
    public required init(initialState: State) {
        self.stateBinder = Binder(initialState)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        observeOutput({ [weak self] output in
            guard let strongSelf = self else { return }
            observer(output, strongSelf .stateBinder.value)
        })
    }
    
}

private func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}

internal class StoreAdapter<_StoreDefinition: StoreDefinition, _ViewDefinition: ViewDefinition>: StateBindable {
    typealias _Store = Store<_StoreDefinition>
    typealias State = _StoreDefinition.State
    typealias Action = _StoreDefinition.Action
    typealias ViewState = _ViewDefinition.ViewState
    typealias ViewAction = _ViewDefinition.ViewAction
    
    typealias R = ViewState
    
    typealias StateMap = (State) -> ViewState
    typealias ActionMap = (ViewAction) -> Action
    
    private let stateMap: StateMap
    private let actionMap: ActionMap
    
    private let store: _Store
    
    internal init(_ store: _Store, stateMap: @escaping StateMap, actionMap: @escaping ActionMap) {
        self.store = store
        self.stateMap = stateMap
        self.actionMap = actionMap
    }
    
    func dispatchAction(_ viewAction: ViewAction) {
        let action = actionMap(viewAction)
        store.handleAction(action)
    }
    
    var stateBinder: Binder<State> {
        return store.stateBinder
    }
    
    var transform: (State) -> ViewState {
        return stateMap
    }
    
}

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
