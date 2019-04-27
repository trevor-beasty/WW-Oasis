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
        return ScreenPlacer<PageContext>() { toPlace throws -> PageContext in
            guard let context = self.context.boxed else {
                throw ScreenPlacerBaseError<UIPageViewController>.nilBase(self.context)
            }
            context.setViewControllers([toPlace], direction: .forward, animated: true, completion: nil)
            return PageContext.init(context: self.context)
        }
    }
    
}

extension ScreenContextType {
    
    func asModalContext() -> ModalContext {
        return ModalContext.init(context: context.map({ $0 as UIViewController }))
    }
    
    func makeModalPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer.init(context.map({ $0 as UIViewController })).asPlacer()
    }
    
    func makeNavigationEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        return makeModalPlacer()
            .embedIn(navigationController)
    }
    
    func makeNavigationPlacer() -> ScreenPlacer<NavigationContext> {
        return ScreenPlacer<NavigationContext>.init({ viewController throws in
            guard let context = self.context.boxed else {
                throw ScreenPlacerBaseError<UIViewController>.nilBase(self.context.map({ $0 as UIViewController }))
            }
            let navigationController = UINavigationController(rootViewController: viewController)
            context.present(navigationController, animated: true, completion: nil)
            return NavigationContext.init(context: WeakBox<UINavigationController>(navigationController))
        })
    }
    
}

extension ScreenContextType where Context: UINavigationController {
    
    func makeNavigationPlacer() -> ScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(context.map({ $0 as UINavigationController })).asPlacer()
    }
    
}
