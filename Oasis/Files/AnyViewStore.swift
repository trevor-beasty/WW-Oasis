//
//  AnyViewStore.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/29/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol ViewStoreType: ViewDefinition, BinderHostType where Binder.Value == ViewState {
    var viewState: ViewState { get }
    func dispatchAction(_ viewAction: ViewAction)
}

public class AnyViewStore<ViewState, ViewAction>: ViewStoreType {
    
    public let binder: IndirectBinder<ViewState>
    private let _viewState: () -> ViewState
    private let _dispatchAction: (ViewAction) -> Void
    
    internal init<ViewStore: ViewStoreType>(_ viewStore: ViewStore) where ViewStore.ViewState == ViewState, ViewStore.ViewAction == ViewAction {
        self.binder = IndirectBinder<ViewState>.init(viewStore.binder)
        self._viewState = { return viewStore.viewState }
        self._dispatchAction = viewStore.dispatchAction
    }
    
    public var viewState: ViewState {
        return _viewState()
    }
    
    public func dispatchAction(_ viewAction: ViewAction) {
        _dispatchAction(viewAction)
    }
    
}

internal class ViewStoreAdapter<Store: StoreType, View: ViewType>: ViewStoreType {
    typealias ViewState = View.ViewState
    typealias ViewAction = View.ViewAction
    
    public let binder: IndirectBinder<ViewState>
    private let _viewState: () -> ViewState
    private let _dispatchAction: (ViewAction) -> Void
    
    internal init(_ store: Store, stateMap: @escaping (Store.State) -> ViewState, actionMap: @escaping (ViewAction) -> Store.Action) {
        self.binder = IndirectBinder<View.ViewState>.init(store.binder, stateMap)
        
        self._viewState = {
            return stateMap(store.state)
        }
        
        self._dispatchAction = { viewAction in
            let action = actionMap(viewAction)
            store.handleAction(action)
        }
        
    }
    
    var viewState: ViewState {
        return _viewState()
    }
    
    func dispatchAction(_ viewAction: ViewAction) {
        _dispatchAction(viewAction)
    }
    
}

