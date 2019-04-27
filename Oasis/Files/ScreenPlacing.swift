//
//  ScreenPlacing.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

protocol ScreenPlacerType {
    associatedtype NextScreenContext: ScreenContextType
    
    func place(_ viewController: UIViewController) -> NextScreenContext
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

struct WindowPlacer: ScreenPlacerType {
    
    let window: UIWindow
    
    func place(_ viewController: UIViewController) -> ModalContext {
        window.rootViewController = viewController
        return ModalContext(context: viewController)
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
            return NavigationContext.init(context: self.navigationController)
        }
    }
    
}

struct TabBarPlacer {
    
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
                return TabBarContext.init(context: self.tabBarController)
            }
        })
        
    }
    
}

struct ScreenPlacer<NextScreenContext: ScreenContextType>: ScreenPlacerType {
    
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
    
    func asPlacer() -> ScreenPlacer<NextScreenContext> {
        return ScreenPlacer<NextScreenContext>.init(self)
    }
    
    func embedIn(_ tabBarController: UITabBarController, tabCount: Int) -> [ScreenPlacer<TabBarContext>] {
        return TabBarPlacer(tabBarController).makePlacers(tabCount) { tabBarController in
            _ = self.place(tabBarController)
        }
    }
    
    func embedIn(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return RootNavigationPlacer(navigationController).makePlacer() { tabBarController in
            _ = self.place(tabBarController)
        }
    }
    
}
