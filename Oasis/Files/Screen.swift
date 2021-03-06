//
//  Screen.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/30/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

open class Screen<Store: StoreType, View: ViewType> where View: UIViewController {
    public typealias State = Store.State
    public typealias Action = Store.Action
    public typealias ViewState = View.ViewState
    public typealias ViewAction = View.ViewAction
    
    public let store: AnyStore<Store.State, Store.Action, Store.Output>
    public let viewController: UIViewController
    
    public required init(_ store: Store? = nil, initialState: Store.State) {
        let store = store ?? Store.init(initialState)
        let viewStoreAdapter = ViewStoreAdapter<Store, View>.init(store, stateMap: type(of: self).mapState, actionMap: type(of: self).mapViewAction)
        self.store = store.asStore()
        self.viewController = View.init(viewStore: viewStoreAdapter.asViewStore())
    }
    
    open class func mapState(_ state: State) -> ViewState {
        return lassoAbstractMethod()
    }
    
    open class func mapViewAction(_ viewAction: ViewAction) -> Action {
        return lassoAbstractMethod()
    }
    
}
