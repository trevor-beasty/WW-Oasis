//
//  ScreenContext.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

public protocol ScreenContextType: AnyObject {
    associatedtype Context: UIViewController
    associatedtype RecursiveContext: RecursiveScreenContextType
    
    var context: WeakBox<Context> { get }
    func makeNextPlacer() -> ScreenPlacer<RecursiveContext>
}

public protocol RecursiveScreenContextType: ScreenContextType where RecursiveContext == Self { }

public class ModalContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UIViewController>
    
    internal init(_ viewController: UIViewController) {
        self.context = WeakBox(viewController)
    }
    
    public func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return modalPlacer(context).asPlacer()
    }
    
}

public class NavigationContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UINavigationController>
    
    internal init(_ navigationController: UINavigationController) {
        self.context = WeakBox(navigationController)
    }
    
    public func makeNextPlacer() -> ScreenPlacer<NavigationContext> {
        return ScreenPlacerSink<UINavigationController, NavigationContext>.init(.weak(context)) { base, toPlace in
            base.pushViewController(toPlace, animated: true)
            return NavigationContext(base)
        }.asPlacer()
    }
    
}

public class TabBarContext: ScreenContextType {
    
    public let context: WeakBox<UITabBarController>
    
    internal init(_ tabBarController: UITabBarController) {
        self.context = WeakBox(tabBarController)
    }
    
    public func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return modalPlacer(context.map({ $0 as UIViewController })).asPlacer()
    }
    
}

public class PageContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UIPageViewController>
    
    internal init(_ pageViewController: UIPageViewController) {
        self.context = WeakBox(pageViewController)
    }
    
    public func makeNextPlacer() -> ScreenPlacer<PageContext> {
        return ScreenPlacerSink<UIPageViewController, PageContext>(.weak(context)) { base, toPlace in
            base.setViewControllers([toPlace], direction: .forward, animated: true, completion: nil)
            return PageContext(base)
        }.asPlacer()
    }
    
}

extension ScreenContextType {
    
    public func makeModalPlacer() -> ScreenPlacer<ModalContext> {
        return modalPlacer(context.map({ $0 as UIViewController })).asPlacer()
    }
    
    public func makeNavigationEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return makeModalPlacer()
            .makeNavigationPlacer(navigationController)
    }
    
}
