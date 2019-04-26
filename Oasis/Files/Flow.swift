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
    associatedtype ScreenPlacer: ScreenPlacerType where ScreenPlacer.ScreenContext == Self

    var container: Containment { get }
    func makePlacer() -> ScreenPlacer

}

protocol ScreenPlacerType {
    associatedtype ScreenContext: ScreenContextType

    func place(_ viewController: UIViewController) -> ScreenContext
}

struct ScreenContextSwitcher<ScreenPlacer: ScreenPlacerType>: ScreenPlacerType {
    typealias ScreenContext = ScreenPlacer.ScreenContext
    
    let switchContext: () -> Void
    let screenPlacer: ScreenPlacer
    
    func place(_ viewController: UIViewController) -> ScreenContext {
        switchContext()
        return screenPlacer.place(viewController)
    }
    
}

protocol ModalContextType: ScreenContextType where Containment == UIViewController { }

protocol ModalPlacerType: ScreenPlacerType where ScreenContext.Containment == UIViewController { }

protocol NavigationContextType: ScreenContextType where Containment == UINavigationController { }

protocol NavigationPlacerType: ScreenPlacerType where ScreenContext.Containment == UINavigationController { }

struct ModalContext: ModalContextType {
    
    let container: UIViewController
    
    func makePlacer() -> ModalPlacer {
        return ModalPlacer.init(presenting: container)
    }
    
}

struct ModalPlacer: ModalPlacerType {
    
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

struct NavigationPlacer: NavigationPlacerType {
    
    let navigationController: UINavigationController
    
    func place(_ viewController: UIViewController) -> NavigationContext {
        navigationController.pushViewController(viewController, animated: true)
        return NavigationContext.init(container: navigationController)
    }
    
}

extension ScreenContextType {
    
    func makeModalPlacer() -> ModalPlacerType {
        return ModalPlacer.init(presenting: container)
    }
    
    func makeNavigationPlacer() -> NavigationPlacerType {
        return ScreenContextSwitcher<NavigationPlacer>.init(switchContext: <#T##() -> Void#>, screenPlacer: <#T##NavigationPlacer#>)
    }
    
}

//struct ScreenContext<Containment: UIViewController> {
//
//
//
//}
//
//struct ScreenPlacer<Containment: UIViewController> {
//
//    func place(_ toPlace: UIViewController) -> ScreenContext<Containment> {
//
//    }
//
//}
