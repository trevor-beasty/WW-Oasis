//
//  AnyViewStore.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/29/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol ViewStoreType: ViewDefinition, BinderHostType where BindableValue == ViewState {
    var viewState: ViewState { get }
    func dispatchAction(_ viewAction: ViewAction)
}

public class AnyViewStore<ViewState, ViewAction>: ViewStoreType {
    
    private let indirectBinder: IndirectBinder<ViewState>
    private let _dispatchAction: (ViewAction) -> Void
    
    internal init<ViewStore: ViewStoreType>(_ viewStore: ViewStore) where ViewStore.ViewState == ViewState, ViewStore.ViewAction == ViewAction {
        self.indirectBinder = IndirectBinder<ViewState>.init(viewStore.binder)
        self._dispatchAction = viewStore.dispatchAction
    }
    
    public func dispatchAction(_ viewAction: ViewAction) {
        _dispatchAction(viewAction)
    }
    
    public var binder: AnyBinder<ViewState> {
        return indirectBinder.asBinder()
    }
    
}

internal class ViewStoreAdapter<Store: AbstractStoreType, View: ViewType>: ViewStoreType {
    typealias ViewState = View.ViewState
    typealias ViewAction = View.ViewAction
    
    private let indirectBinder: IndirectBinder<ViewState>
    private let _dispatchAction: (ViewAction) -> Void
    
    internal init(_ store: Store, stateMap: @escaping (Store.State) -> ViewState, actionMap: @escaping (ViewAction) -> Store.Action) {
        self.indirectBinder = IndirectBinder<View.ViewState>.init(store.binder, stateMap)
        
        self._dispatchAction = { viewAction in
            let action = actionMap(viewAction)
            store.handleAction(action)
        }
        
    }
    
    func dispatchAction(_ viewAction: ViewAction) {
        _dispatchAction(viewAction)
    }
    
    public var binder: AnyBinder<ViewState> {
        return indirectBinder.asBinder()
    }
    
}

extension ViewStoreType {
    
    public var viewState: ViewState {
        return binder.value
    }
    
    internal func asViewStore() -> AnyViewStore<ViewState, ViewAction> {
        return AnyViewStore<ViewState, ViewAction>.init(self)
    }
    
}
