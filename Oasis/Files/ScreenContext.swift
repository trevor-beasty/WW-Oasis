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
    
    var context: Context { get }
    func makeNextPlacer() -> AnyScreenPlacer<RecursiveContext>
}

protocol RecursiveScreenContextType: ScreenContextType where RecursiveContext == Self { }

struct ModalContext: RecursiveScreenContextType {
    
    let context: UIViewController
    
    func makeNextPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer(presenting: context).asAnyPlacer()
    }
    
}

struct NavigationContext: RecursiveScreenContextType {
    
    let context: UINavigationController
    
    func makeNextPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer(navigationController: context).asAnyPlacer()
    }
    
}

struct TabBarContext: ScreenContextType {
    
    let context: UITabBarController
    
    func makeNextPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer(presenting: context).asAnyPlacer()
    }
    
}

extension ScreenContextType {
    
    func asModalContext() -> ModalContext {
        return ModalContext.init(context: context)
    }
    
    func makeModalPlacer() -> AnyScreenPlacer<ModalContext> {
        return ModalPlacer.init(presenting: context).asAnyPlacer()
    }
    
    func makeNavEmbeddedModalPlacer(_ navigationController: UINavigationController) -> AnyScreenPlacer<NavigationContext> {
        let modalPlacer = makeModalPlacer()
        return RootNavigationPlacer(navigationController).makePlacer() { rootScreen in
            _ = modalPlacer.place(rootScreen)
        }
    }
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return AnyScreenPlacer<NavigationContext>.init({ viewController in
            let navigationController = UINavigationController(rootViewController: viewController)
            self.context.present(navigationController, animated: true, completion: nil)
            return NavigationContext.init(context: navigationController)
        })
    }
    
}

extension ScreenContextType where Context: UINavigationController {
    
    func makeNavigationPlacer() -> AnyScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(navigationController: context).asAnyPlacer()
    }
    
}
