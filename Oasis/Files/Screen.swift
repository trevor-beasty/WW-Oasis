//
//  Screen.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/30/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

public protocol ScreenType {
    associatedtype Store: StoreType
    associatedtype View: ViewType where View: UIViewController
}

extension ScreenType {
    
    static func create(with store: Store?, initialState: Store.State, stateMap: @escaping (Store.State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Store.Action) -> (store: AnyStore<Store.State, Store.Action, Store.Output>, viewController: UIViewController) {
        let store = store ?? Store.init(initialState)
        let viewStoreAdapter = ViewStoreAdapter<Store, View>.init(store, stateMap: stateMap, actionMap: actionMap)
        let viewController = View.init(viewStore: viewStoreAdapter.asViewStore())
        return (store.asStore(), viewController)
    }
    
}
