//
//  ScreenPlacing.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

public enum ScreenPlacerBaseError<Base: AnyObject>: Error {
    case nilBase(WeakBox<Base>)
}

public enum ScreenPlacerError: Error {
    case placementExhausted
}

public protocol ScreenPlacerType: AnyObject {
    associatedtype NextScreenContext: ScreenContextType
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext
}

internal class ScreenPlacerSink<Base: AnyObject, NextScreenContext: ScreenContextType>: ScreenPlacerType {
    typealias Place = (Base, UIViewController) throws -> NextScreenContext
    
    private let base: WeakStrong<Base>
    private let place: Place
    private var didPlace = false
    
    init(_ base: WeakStrong<Base>, place: @escaping Place) {
        self.base = base
        self.place = place
    }
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext {
        guard !didPlace else {
            throw ScreenPlacerError.placementExhausted
        }
        let base: Base
        switch self.base {
        case .strong(let _base):
            base = _base
        case .weak(let weakBox):
            guard let _base = weakBox.boxed else {
                throw ScreenPlacerBaseError<Base>.nilBase(weakBox)
            }
            base = _base
        }
        let nextScreenContext = try place(base, viewController)
        didPlace = true
        return nextScreenContext
    }
    
}

internal class ModalPlacer: ScreenPlacerSink<UIViewController, ModalContext> {
    
    init(_ presenting: WeakBox<UIViewController>) {
        super.init(.weak(presenting)) { (base, toPlace) -> ModalContext in
            base.present(toPlace, animated: true, completion: nil)
            return ModalContext.init(context: WeakBox<UIViewController>(toPlace))
        }
    }
    
}

internal class NavigationPlacer: ScreenPlacerSink<UINavigationController, NavigationContext> {
    
    init(_ navigationController: WeakBox<UINavigationController>) {
        super.init(.weak(navigationController)) { (base, toPlace) -> NavigationContext in
            base.pushViewController(toPlace, animated: true)
            return NavigationContext.init(context: WeakBox<UINavigationController>(base))
        }
    }
    
}

internal class WindowPlacer: ScreenPlacerSink<UIWindow, ModalContext> {
    
    init(_ window: WeakBox<UIWindow>) {
        super.init(.weak(window)) { (base, toPlace) -> ModalContext in
            base.rootViewController = toPlace
            return ModalContext(context: WeakBox<UIViewController>(toPlace))
        }
    }
    
}

public class ScreenPlacer<NextScreenContext: ScreenContextType>: ScreenPlacerType {
    
    private let _place: (UIViewController) throws -> NextScreenContext
    
    init<ScreenPlacer: ScreenPlacerType>(_ screenPlacer: ScreenPlacer) where ScreenPlacer.NextScreenContext == NextScreenContext {
        self._place = screenPlacer.place
    }
    
    public func place(_ viewController: UIViewController) throws -> NextScreenContext {
        return try _place(viewController)
    }
    
}

extension ScreenPlacerType {
    
    internal func asPlacer() -> ScreenPlacer<NextScreenContext> {
        return ScreenPlacer<NextScreenContext>.init(self)
    }
    
    public func embedIn(_ tabBarController: UITabBarController, tabCount: Int) -> [ScreenPlacer<TabBarContext>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                tabBarController.setViewControllers(placed, animated: false)
                _ = try? self.place(tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> ScreenPlacer<TabBarContext> in
            return ScreenPlacerSink<UITabBarController, TabBarContext>(.strong(tabBarController)) { base, toPlace in
                placingBuffer[index] = toPlace
                return TabBarContext.init(context: WeakBox<UITabBarController>(base))
            }.asPlacer()
        })

    }
    
    public func embedIn(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return ScreenPlacerSink<UINavigationController, NavigationContext>(.strong(navigationController)) { base, toPlace in
            base.viewControllers = [toPlace]
            _ = try? self.place(base)
            return NavigationContext.init(context: WeakBox<UINavigationController>(base))
        }.asPlacer()
    }
    
}
