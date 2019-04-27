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
    func makeNextPlacer() -> ScreenPlacer<RecursiveContext>
}

protocol RecursiveScreenContextType: ScreenContextType where RecursiveContext == Self { }

struct ModalContext: RecursiveScreenContextType {
    
    let context: UIViewController
    
    func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer(presenting: context).asPlacer()
    }
    
}

struct NavigationContext: RecursiveScreenContextType {
    
    let context: UINavigationController
    
    func makeNextPlacer() -> ScreenPlacer<NavigationContext> {
        return NavigationPlacer(navigationController: context).asPlacer()
    }
    
}

struct TabBarContext: ScreenContextType {
    
    let context: UITabBarController
    
    func makeNextPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer(presenting: context).asPlacer()
    }
    
}

//struct WindowContext: ScreenContextType {
//
//    let context: UIWindow
//
//    func makeNextPlacer() -> ScreenPlacer<ModalContext> {
//        return ScreenPlacer<ModalContext>() { toPlace in
//            self.context.rootViewController = toPlace
//            return ModalContext.init(context: toPlace)
//        }
//    }
//
//}

extension ScreenContextType {
    
    func asModalContext() -> ModalContext {
        return ModalContext.init(context: context)
    }
    
    func makeModalPlacer() -> ScreenPlacer<ModalContext> {
        return ModalPlacer.init(presenting: context).asPlacer()
    }
    
    func makeNavEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<NavigationContext> {
        let modalPlacer = makeModalPlacer()
        return RootNavigationPlacer(navigationController).makePlacer() { rootScreen in
            _ = modalPlacer.place(rootScreen)
        }
    }
    
    func makeNavigationPlacer() -> ScreenPlacer<NavigationContext> {
        return ScreenPlacer<NavigationContext>.init({ viewController in
            let navigationController = UINavigationController(rootViewController: viewController)
            self.context.present(navigationController, animated: true, completion: nil)
            return NavigationContext.init(context: navigationController)
        })
    }
    
}

extension ScreenContextType where Context: UINavigationController {
    
    func makeNavigationPlacer() -> ScreenPlacer<NavigationContext> {
        return NavigationPlacer.init(navigationController: context).asPlacer()
    }
    
}
