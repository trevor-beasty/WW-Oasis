//
//  ScreenContext.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

public protocol ScreenContextType {
    associatedtype Context: UIViewController
    associatedtype RecursiveContext: RecursiveScreenContextType
    
    var context: WeakBox<Context> { get }
    func makeNextPlacer() -> ScreenPlacer<RecursiveContext>
}

public protocol RecursiveScreenContextType: ScreenContextType where RecursiveContext == Self { }

public struct ModalContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UIViewController>
    
    public func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return modalPlacer(context).asPlacer()
    }
    
}

public struct NavigationContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UINavigationController>
    
    public func makeNextPlacer() -> ScreenPlacer<NavigationContext> {
        return ScreenPlacerSink<UINavigationController, NavigationContext>.init(.weak(context)) { base, toPlace in
            base.pushViewController(toPlace, animated: true)
            return NavigationContext.init(context: WeakBox(base))
        }.asPlacer()
    }
    
}

public struct TabBarContext: ScreenContextType {
    
    public let context: WeakBox<UITabBarController>
    
    public func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return modalPlacer(context.map({ $0 as UIViewController })).asPlacer()
    }
    
}

public struct PageContext: RecursiveScreenContextType {
    
    public let context: WeakBox<UIPageViewController>
    
    public func makeNextPlacer() -> ScreenPlacer<PageContext> {
        return ScreenPlacerSink<UIPageViewController, PageContext>(.weak(context)) { base, toPlace in
            base.setViewControllers([toPlace], direction: .forward, animated: true, completion: nil)
            return PageContext.init(context: WeakBox(base))
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
