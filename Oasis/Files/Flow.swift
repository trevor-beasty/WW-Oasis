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
    associatedtype Containment: UIViewController

    var container: Containment { get }
}

protocol ScreenPlacerType {
    associatedtype ScreenContext: ScreenContextType

    func place(_ viewController: UIViewController) -> ScreenContext
}

struct ModalContext: ScreenContextType {
    
    let container: UIViewController
    
}

struct NavigationContext: ScreenContextType {
    
    let container: UINavigationController
    
}

struct ModalPlacer: ScreenPlacerType {
    
    let presenting: UIViewController
    
    func place(_ viewController: UIViewController) -> ModalContext {
        presenting.present(viewController, animated: true, completion: nil)
        return ModalContext.init(container: viewController)
    }
    
}

struct NavigationPlacer: ScreenPlacerType {
    
    let navigationController: UINavigationController
    
    func place(_ viewController: UIViewController) -> NavigationContext {
        navigationController.pushViewController(viewController, animated: true)
        return NavigationContext.init(container: navigationController)
    }
    
}

extension ScreenContextType {
    
    func makeModalPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer.init(presenting: container).asAnyPlacer()
    }
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return AnyScreenPlacer<NavigationContext>.init({ viewController in
            let navigationController = UINavigationController(rootViewController: viewController)
            self.container.present(navigationController, animated: true, completion: nil)
            return NavigationContext.init(container: navigationController)
        })
    }
    
}

extension ScreenContextType where Containment: UINavigationController {
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(navigationController: container).asAnyPlacer()
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
