//
//  StoreAdapter.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

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
    
    var stateTransform: (State) -> ViewState {
        return stateMap
    }
    
}
