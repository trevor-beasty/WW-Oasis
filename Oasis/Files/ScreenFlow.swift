//
//  ScreenFlow.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

class ScreenFlow<Output, ScreenContext: UIViewController>: Module<None, Output> {
    
    open func start(with screenPlacer: ScreenPlacer<ScreenContext>) throws {
        return lassoAbstractMethod()
    }

}

class UnitaryScreenFlow<Store: StoreType, View: ViewType, ScreenContext: UIViewController>: Module<None, Store.Output> where View: UIViewController {
    
    public private(set) weak var screenContext: ScreenContext?
    public private(set) var store: AnyStore<Store.State, Store.Action, Store.Output>?
    
    open class func screenType() -> Screen<Store, View>.Type {
        return lassoAbstractMethod()
    }
    
    func start(with store: Store? = nil, screenPlacer: ScreenPlacer<ScreenContext>, initialState: Store.State) throws {
        let viewController = assembleViewController(with: store, initialState: initialState)
        screenContext = try screenPlacer.place(viewController)
    }
    
    private func assembleViewController(with store: Store? = nil, initialState: Store.State) -> UIViewController {
        let screen = type(of: self).screenType().init(store, initialState: initialState)
        screen.store.bind(self)
        
        screen.store.observeStatefulOutput { [weak self] (output, state) in
            guard let strongSelf = self else { return }
            strongSelf.handleOutput(output, state: state, screenContext: strongSelf.screenContext)
        }
        
        self.store = screen.store
        return screen.viewController
    }
    
    open func handleOutput(_ output: Store.Output, state: Store.State, screenContext: ScreenContext?) {
        return lassoAbstractMethod()
    }
    
}
