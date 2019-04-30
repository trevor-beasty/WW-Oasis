//
//  Store.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

public protocol StoreDefinition: ModuleDefinition {
    associatedtype State
}

public protocol StoreType: StoreDefinition, BinderHostType, ObjectBindable where Binder.Value == State {
    var state: State { get }
    func handleAction(_ action: Action)
    func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void)
}

open class Store<Definition: StoreDefinition>: Module<Definition.Action, Definition.Output>, StoreType {
    public typealias State = Definition.State
    
    public let binder: SourceBinder<State>
    public let objectBinder = ObjectBinder()
    
    public init(initialState: State) {
        self.binder = SourceBinder(initialState)
    }
    
    public var state: State {
        return binder.value
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        observeOutput({ [weak self] output in
            guard let strongSelf = self else { return }
            observer(output, strongSelf.binder.value)
        })
    }
    
}
