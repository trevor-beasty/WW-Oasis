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

struct RootNavigationPlacer {
    
    private let navigationController: UINavigationController
    
    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func makePlacer(placeNavigationController: @escaping (UINavigationController) -> Void) -> AnyScreenPlacer<NavigationContext> {
        return AnyScreenPlacer<NavigationContext>() { toPlace -> NavigationContext in
            self.navigationController.viewControllers = [toPlace]
            placeNavigationController(self.navigationController)
            return NavigationContext.init(context: self.navigationController)
        }
    }
    
}

struct RootTabBarPlacer {
    
    private let tabBarController: UITabBarController
    
    init(_ tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func makePlacers(_ tabCount: Int, placeTabBar: @escaping (UITabBarController) -> Void) -> [AnyScreenPlacer<TabBarContext>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                self.tabBarController.setViewControllers(placed, animated: false)
                placeTabBar(self.tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> AnyScreenPlacer<TabBarContext> in
            return AnyScreenPlacer<TabBarContext>() { toPlace in
                placingBuffer[index] = toPlace
                return TabBarContext.init(context: self.tabBarController)
            }
        })
        
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
    
    func embedIn(_ tabBarController: UITabBarController, tabCount: Int) -> [AnyScreenPlacer<TabBarContext>] {
        return RootTabBarPlacer(tabBarController).makePlacers(tabCount) { tabBarController in
            _ = self.place(tabBarController)
        }
    }
    
    func embedIn(_ navigationController: UINavigationController) -> AnyScreenPlacer<NavigationContext> {
        return RootNavigationPlacer(navigationController).makePlacer() { tabBarController in
            _ = self.place(tabBarController)
        }
    }
    
}
