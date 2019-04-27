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
    associatedtype NextScreenContext: ScreenContextType

    func place(_ viewController: UIViewController) -> NextScreenContext
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

protocol RootScreenType where Self: UIViewController {
    static func createEmptyRoot() -> Self
}

struct RootNavigationPlacer<RootScreen: RootScreenType> where RootScreen: UINavigationController {

    private let navigationController: UINavigationController
    
    init() {
        self.navigationController = RootScreen.createEmptyRoot()
    }
    
    func makePlacer(placeNavigationController: @escaping (UINavigationController) -> Void) -> AnyScreenPlacer<NavigationContext> {
        return AnyScreenPlacer<NavigationContext>() { toPlace -> NavigationContext in
            self.navigationController.set(rootViewController: toPlace, animated: false)
            placeNavigationController(self.navigationController)
            return NavigationContext.init(context: self.navigationController)
        }
    }
    
}

struct RootTabBarPlacer<RootScreen: RootScreenType> where RootScreen: UITabBarController {
    
    private let tabBarController: UITabBarController
    
    init() {
        self.tabBarController = RootScreen.createEmptyRoot()
    }
    
    func makePlacers(_ tabCount: Int, placeTabBar: @escaping (UITabBarController) -> Void) -> [AnyScreenPlacer<ModalContext>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                self.tabBarController.setViewControllers(placed, animated: false)
                placeTabBar(self.tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> AnyScreenPlacer<ModalContext> in
            return AnyScreenPlacer<ModalContext>() { toPlace in
                placingBuffer[index] = toPlace
                return ModalContext.init(context: self.tabBarController)
            }
        })
        
    }
    
}

extension ScreenContextType {
    
    func makeModalPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer.init(presenting: context).asAnyPlacer()
    }
    
    func makeNavEmbeddedModalPlacer<RootScreen: RootScreenType>(_ rootScreenType: RootScreen.Type) -> AnyScreenPlacer<NavigationContext> where RootScreen: UINavigationController {
        let modalPlacer = makeModalPlacer()
        return RootNavigationPlacer<RootScreen>().makePlacer() { rootScreen in
            _ = modalPlacer.place(rootScreen)
        }
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

struct AnyScreenPlacer<NextScreenContext: ScreenContextType>: ScreenPlacerType {
    
    private let _place: (UIViewController) -> NextScreenContext
    
    init<ScreenPlacer: ScreenPlacerType>(_ screenPlacer: ScreenPlacer) where ScreenPlacer.NextScreenContext == NextScreenContext {
        self._place = screenPlacer.place
    }
    
    init(_ _place: @escaping (UIViewController) -> NextScreenContext) {
        self._place = _place
    }
    
    func place(_ viewController: UIViewController) -> NextScreenContext {
        return _place(viewController)
    }
    
}

extension ScreenPlacerType {
    
    func asAnyPlacer() -> AnyScreenPlacer<NextScreenContext> {
        return AnyScreenPlacer<NextScreenContext>.init(self)
    }
    
}
