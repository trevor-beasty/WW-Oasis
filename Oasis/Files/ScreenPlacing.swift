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
    associatedtype NextScreenContext: UIViewController
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext
}

internal class ScreenPlacerSink<Base: AnyObject, NextScreenContext: UIViewController>: ScreenPlacerType {
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

internal func modalPlacer(_ presenting: UIViewController) -> ScreenPlacerSink<UIViewController, UIViewController> {
    return ScreenPlacerSink<UIViewController, UIViewController>.init(.weak(WeakBox(presenting))) { (base, toPlace) -> UIViewController in
        base.present(toPlace, animated: true, completion: nil)
        return toPlace
    }
}

public class ScreenPlacer<NextScreenContext: UIViewController>: ScreenPlacerType {
    
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
    
    public func makeTabBarPlacers(_ tabBarController: UITabBarController, tabCount: Int) -> [ScreenPlacer<UITabBarController>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabCount else { return }
                tabBarController.setViewControllers(placed, animated: false)
                _ = try? self.place(tabBarController)
            }
        }
        
        return (0..<tabCount).map({ index -> ScreenPlacer<UITabBarController> in
            return ScreenPlacerSink<UITabBarController, UITabBarController>(.strong(tabBarController)) { base, toPlace in
                placingBuffer[index] = toPlace
                return base
            }.asPlacer()
        })

    }
    
    public func makeNavigationPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<UINavigationController> {
        return ScreenPlacerSink<UINavigationController, UINavigationController>(.strong(navigationController)) { base, toPlace in
            base.viewControllers = [toPlace]
            _ = try? self.place(base)
            return base
        }.asPlacer()
    }
    
}

enum ScreenPlacement {
    
    public static func makeWindowPlacer(_ window: UIWindow) -> ScreenPlacer<UIViewController> {
        return ScreenPlacerSink<UIWindow, UIViewController>.init(.weak(WeakBox(window)), place: { (base, toPlace) -> UIViewController in
            base.rootViewController = toPlace
            return toPlace
        }).asPlacer()
    }
    
    public static func make<Base: AnyObject, NextScreenContext: UIViewController>(_ base: WeakBox<Base>, place: @escaping (Base, UIViewController) -> NextScreenContext) -> ScreenPlacer<NextScreenContext> {
        return ScreenPlacerSink<Base, NextScreenContext>.init(.weak(base), place: place).asPlacer()
    }
    
}

extension UIViewController {
    
    public func makeModalPlacer() -> ScreenPlacer<UIViewController> {
        return modalPlacer(self).asPlacer()
    }
    
    public func makeNavigationEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<UINavigationController> {
        return makeModalPlacer()
            .makeNavigationPlacer(navigationController)
    }
    
}
