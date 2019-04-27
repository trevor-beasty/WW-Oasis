//
//  ScreenPlacing.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

enum ScreenPlacerError<Base: AnyObject>: Error {
    case nilBase(WeakBox<Base>)
}

protocol ScreenPlacerType {
    associatedtype NextScreenContext: ScreenContextType
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext
}


struct ModalPlacer: ScreenPlacerType {
    
    let presenting: WeakBox<UIViewController>
    
    func place(_ viewController: UIViewController) throws -> ModalContext {
        guard let presenting = presenting.boxed else {
            throw ScreenPlacerError<UIViewController>.nilBase(self.presenting)
        }
        presenting.present(viewController, animated: true, completion: nil)
        return ModalContext.init(context: WeakBox<UIViewController>(viewController))
    }
    
}

struct NavigationPlacer: ScreenPlacerType {
    
    let navigationController: WeakBox<UINavigationController>
    
    func place(_ viewController: UIViewController) throws -> NavigationContext {
        guard let navigationController = navigationController.boxed else {
            throw ScreenPlacerError<UINavigationController>.nilBase(self.navigationController)
        }
        navigationController.pushViewController(viewController, animated: true)
        return NavigationContext.init(context: self.navigationController)
    }
    
}

struct WindowPlacer: ScreenPlacerType {
    
    let window: WeakBox<UIWindow>
    
    func place(_ viewController: UIViewController) throws -> ModalContext {
        guard let window = window.boxed else {
            throw ScreenPlacerError<UIWindow>.nilBase(self.window)
        }
        window.rootViewController = viewController
        return ModalContext(context: WeakBox<UIViewController>(viewController))
    }
    
}

struct RootNavigationPlacer {
    
    private let navigationController: UINavigationController
    
    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func makePlacer(placeNavigationController: @escaping (UINavigationController) -> Void) -> ScreenPlacer<NavigationContext> {
        return ScreenPlacer<NavigationContext>() { toPlace -> NavigationContext in
            self.navigationController.viewControllers = [toPlace]
            placeNavigationController(self.navigationController)
            return NavigationContext.init(context: WeakBox<UINavigationController>(self.navigationController))
        }
    }
    
}

struct RootTabBarPlacer {
    
    private let tabBarController: UITabBarController
    
    init(_ tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func makePlacers(_ tabCount: Int, placeTabBar: @escaping (UITabBarController) -> Void) -> [ScreenPlacer<TabBarContext>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                self.tabBarController.setViewControllers(placed, animated: false)
                placeTabBar(self.tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> ScreenPlacer<TabBarContext> in
            return ScreenPlacer<TabBarContext>() { toPlace in
                placingBuffer[index] = toPlace
                return TabBarContext.init(context: WeakBox<UITabBarController>(self.tabBarController))
            }
        })
        
    }
    
}

struct ScreenPlacer<NextScreenContext: ScreenContextType>: ScreenPlacerType {
    
    private let _place: (UIViewController) throws -> NextScreenContext
    
    init<ScreenPlacer: ScreenPlacerType>(_ screenPlacer: ScreenPlacer) where ScreenPlacer.NextScreenContext == NextScreenContext {
        self._place = screenPlacer.place
    }
    
    init(_ _place: @escaping (UIViewController) throws -> NextScreenContext) {
        self._place = _place
    }
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext {
        return try _place(viewController)
    }
    
}

extension ScreenPlacerType {
    
    func asPlacer() -> ScreenPlacer<NextScreenContext> {
        return ScreenPlacer<NextScreenContext>.init(self)
    }
    
    func embedIn(_ tabBarController: UITabBarController, tabCount: Int) -> [ScreenPlacer<TabBarContext>] {
        return RootTabBarPlacer(tabBarController).makePlacers(tabCount) { tabBarController in
            _ = try? self.place(tabBarController)
        }
    }
    
    func embedIn(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return RootNavigationPlacer(navigationController).makePlacer() { navigationController in
            _ = try? self.place(navigationController)
        }
    }
    
}
