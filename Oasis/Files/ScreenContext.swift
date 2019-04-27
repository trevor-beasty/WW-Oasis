//
//  ScreenContext.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

protocol ScreenContextType {
    associatedtype Context: UIViewController
    associatedtype RecursiveContext: RecursiveScreenContextType
    
    var context: WeakBox<Context> { get }
    func makeNextPlacer() -> ScreenPlacer<RecursiveContext>
}

protocol RecursiveScreenContextType: ScreenContextType where RecursiveContext == Self { }

struct ModalContext: RecursiveScreenContextType {
    
    let context: WeakBox<UIViewController>
    
    func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer(context).asPlacer()
    }
    
}

struct NavigationContext: RecursiveScreenContextType {
    
    let context: WeakBox<UINavigationController>
    
    func makeNextPlacer() -> ScreenPlacer<NavigationContext> {
        return NavigationPlacer(context).asPlacer()
    }
    
}

struct TabBarContext: ScreenContextType {
    
    let context: WeakBox<UITabBarController>
    
    func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer(context.map({ $0 as UIViewController })).asPlacer()
    }
    
}

struct PageContext: RecursiveScreenContextType {
    
    let context: WeakBox<UIPageViewController>
    
    func makeNextPlacer() -> ScreenPlacer<PageContext> {
        return ScreenPlacerSink<UIPageViewController, PageContext>(.weak(context)) { base, toPlace in
            base.setViewControllers([toPlace], direction: .forward, animated: true, completion: nil)
            return PageContext.init(context: WeakBox(base))
        }.asPlacer()
    }
    
}

extension ScreenContextType {
    
    func makeModalPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer.init(context.map({ $0 as UIViewController })).asPlacer()
    }
    
    func makeNavigationEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return makeModalPlacer()
            .embedIn(navigationController)
    }
    
}
