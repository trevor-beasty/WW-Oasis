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
    
//    init(_ store: Store: )
    
}

//enum Screen {
//
//    enum Context {
//        case window(UIWindow)
//        case navigation(UINavigationController)
//        case modal(UIViewController)
//        case tabBar(UITabBarController)
//    }
//
//    typealias Placer = (UIViewController) -> Context
//
//    enum Placement {
//        case windowRoot
//        case tabBarRoot(index: Int)
//        case modal
//        case navigation
//    }
//
//}
//
//extension Screen.Context {
//
//    func makePlacer(for placement: Screen.Placement) -> Screen.Placer {
//        switch self {
//        case
//        }
//    }
//
//}

protocol ScreenContextType {
    associatedtype Containment: UIViewController
    associatedtype ScreenPlacer: ScreenPlacerType

    var container: Containment { get }
    func makePlacer() -> ScreenPlacer

}

protocol ScreenPlacerType {
    associatedtype ScreenContext: ScreenContextType

    func place(_ viewController: UIViewController) -> ScreenContext
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

protocol ModalContextType: ScreenContextType where Containment == UIViewController { }

protocol NavigationContextType: ScreenContextType where Containment == UINavigationController { }

struct ModalContext: ModalContextType {
    
    let container: UIViewController
    
    func makePlacer() -> ModalPlacer {
        return ModalPlacer.init(presenting: container)
    }
    
}

struct ModalPlacer: ScreenPlacerType {
    
    let presenting: UIViewController
    
    func place(_ viewController: UIViewController) -> ModalContext {
        presenting.present(viewController, animated: true, completion: nil)
        return ModalContext.init(container: viewController)
    }
    
}

struct NavigationContext: NavigationContextType {
    
    let container: UINavigationController
    
    func makePlacer() -> NavigationPlacer {
        return NavigationPlacer.init(navigationController: container)
    }
    
}

struct NavigationPlacer: ScreenPlacerType {
    
    let navigationController: UINavigationController
    
    func place(_ viewController: UIViewController) -> NavigationContext {
        navigationController.pushViewController(viewController, animated: true)
        return NavigationContext.init(container: navigationController)
    }
    
}

struct TabBarContext: ScreenContextType {
    
    let index: Int
    let container: UITabBarController
    
    func makePlacer() -> TabBarPlacer {
        return TabBarPlacer(tabBarController: container, index: index)
    }
    
}

struct TabBarPlacer: ScreenPlacerType {
    
    let tabBarController: UITabBarController
    let index: Int
    
    func place(_ viewController: UIViewController) -> ModalContext {
        tabBarController.viewControllers?[index] = viewController
        return ModalContext.init(container: viewController)
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
    
    func makeTabBarPlacer(with tabBarController: UITabBarController, for index: Int) -> AnyScreenPlacer<ModalContext> {
        return TabBarPlacer.init(tabBarController: tabBarController, index: index).asAnyPlacer()
    }
    
}

extension ScreenContextType where Containment: UINavigationController {
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(navigationController: container).asAnyPlacer()
    }
    
}

extension ScreenPlacerType {
    
    func asAnyPlacer() -> AnyScreenPlacer<ScreenContext> {
        return AnyScreenPlacer<ScreenContext>.init(self)
    }
    
}
