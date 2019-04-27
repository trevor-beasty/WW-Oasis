//
//  ScreenPlacing.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

enum ScreenPlacerBaseError<Base: AnyObject>: Error {
    case nilBase(WeakBox<Base>)
}

enum ScreenPlacerError: Error {
    case placementExhausted
}

protocol ScreenPlacerType {
    associatedtype NextScreenContext: ScreenContextType
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext
}

class ScreenPlacerSink<Base: AnyObject, NextScreenContext: ScreenContextType>: ScreenPlacerType {
    typealias Place = (Base, UIViewController) throws -> NextScreenContext
    
    private let base: WeakBox<Base>
    private let place: Place
    private var didPlace = false
    
    init(_ base: WeakBox<Base>, place: @escaping Place) {
        self.base = base
        self.place = place
    }
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext {
        guard !didPlace else {
            throw ScreenPlacerError.placementExhausted
        }
        guard let base = base.boxed else {
            throw ScreenPlacerBaseError<Base>.nilBase(self.base)
        }
        let nextScreenContext = try place(base, viewController)
        didPlace = true
        return nextScreenContext
    }
    
}

class ModalPlacer: ScreenPlacerSink<UIViewController, ModalContext> {
    
    init(_ presenting: WeakBox<UIViewController>) {
        super.init(presenting) { (base, toPlace) -> ModalContext in
            base.present(toPlace, animated: true, completion: nil)
            return ModalContext.init(context: WeakBox<UIViewController>(toPlace))
        }
    }
    
}

class NavigationPlacer: ScreenPlacerSink<UINavigationController, NavigationContext> {
    
    init(_ navigationController: WeakBox<UINavigationController>) {
        super.init(navigationController) { (base, toPlace) -> NavigationContext in
            base.pushViewController(toPlace, animated: true)
            return NavigationContext.init(context: WeakBox<UINavigationController>(base))
        }
    }
    
}

class WindowPlacer: ScreenPlacerSink<UIWindow, ModalContext> {
    
    init(_ window: WeakBox<UIWindow>) {
        super.init(window) { (base, toPlace) -> ModalContext in
            base.rootViewController = toPlace
            return ModalContext(context: WeakBox<UIViewController>(toPlace))
        }
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
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                tabBarController.setViewControllers(placed, animated: false)
                _ = try? self.place(tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> ScreenPlacer<TabBarContext> in
            return ScreenPlacer<TabBarContext>() { toPlace in
                placingBuffer[index] = toPlace
                return TabBarContext.init(context: WeakBox<UITabBarController>(tabBarController))
            }
        })

    }
    
    func embedIn(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return ScreenPlacer<NavigationContext>() { toPlace -> NavigationContext in
            navigationController.viewControllers = [toPlace]
            _ = try? self.place(navigationController)
            return NavigationContext.init(context: WeakBox<UINavigationController>(navigationController))
        }
    }
    
}
