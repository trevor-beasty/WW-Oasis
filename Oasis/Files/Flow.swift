//
//  Flow.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

class ScreenFlow<Output>: Module<None, Output> { }

class UnitaryScreenFlow<Store: StoreProtocol>: ScreenFlow<Store.Output> {
    
    
    
}

protocol ScreenContextType {
    associatedtype Context: UIViewController
    associatedtype RecursiveContext: ScreenContextType

    var context: Context { get }
    func makeNextPlacer() -> AnyScreenPlacer<RecursiveContext>
}

protocol ScreenPlacerType {
    associatedtype ScreenContext: ScreenContextType

    func place(_ viewController: UIViewController) -> ScreenContext
}

struct ModalContext: ScreenContextType {
    
    let context: UIViewController
    
    func makeNextPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer(presenting: context).asAnyPlacer()
    }
    
}

struct NavigationContext: ScreenContextType {
    
    let context: UINavigationController
    
    func makeNextPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer(navigationController: context).asAnyPlacer()
    }
    
}

struct ModalPlacer: ScreenPlacerType {
    
    let presenting: UIViewController
    
    func place(_ viewController: UIViewController) -> ModalContext {
        presenting.present(viewController, animated: true, completion: nil)
        return ModalContext.init(context: viewController)
    }
    
}

struct NavigationPlacer: ScreenPlacerType {
    
    let navigationController: UINavigationController
    
    func place(_ viewController: UIViewController) -> NavigationContext {
        navigationController.pushViewController(viewController, animated: true)
        return NavigationContext.init(context: navigationController)
    }
    
}

struct RootNavigationPlacer: ScreenPlacerType {
    
    private let placeRoot: (UIViewController) -> Void
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController? = nil, placeRoot: @escaping (UIViewController) -> Void) {
        self.navigationController = navigationController ?? UINavigationController()
        self.placeRoot = placeRoot
    }
    
    func place(_ viewController: UIViewController) -> NavigationContext {
        navigationController.set(rootViewController: viewController, animated: false)
        placeRoot(navigationController)
        return NavigationContext.init(context: navigationController)
    }
    
}

struct RootTabBarPlacer: ScreenPlacerType {
    
    
    
}

extension ScreenContextType {
    
    func makeModalPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer.init(presenting: context).asAnyPlacer()
    }
    
    func makeNavEmbeddedModalPlacer() -> AnyScreenPlacer<NavigationContext> {
        let modalPlacer = makeModalPlacer()
        return RootNavigationPlacer(placeRoot: { root in _ = modalPlacer.place(root) }).asAnyPlacer()
    }
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return AnyScreenPlacer<NavigationContext>.init({ viewController in
            let navigationController = UINavigationController(rootViewController: viewController)
            self.context.present(navigationController, animated: true, completion: nil)
            return NavigationContext.init(context: navigationController)
        })
    }
    
}

extension ScreenContextType where Context: UINavigationController {
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(navigationController: context).asAnyPlacer()
    }
    
}

struct AnyScreenPlacer<ScreenContext: ScreenContextType>: ScreenPlacerType {
    
    private let _place: (UIViewController) -> ScreenContext
    
    init<ScreenPlacer: ScreenPlacerType>(_ screenPlacer: ScreenPlacer) where ScreenPlacer.ScreenContext == ScreenContext {
        self._place = screenPlacer.place
    }
    
    init(_ _place: @escaping (UIViewController) -> ScreenContext) {
        self._place = _place
    }
    
    func place(_ viewController: UIViewController) -> ScreenContext {
        return _place(viewController)
    }
    
}

extension ScreenPlacerType {
    
    func asAnyPlacer() -> AnyScreenPlacer<ScreenContext> {
        return AnyScreenPlacer<ScreenContext>.init(self)
    }
    
}

struct TabBarRootPlacer {
    
    
    
}
