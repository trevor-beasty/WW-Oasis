//
//  FlowContext.swift
//  WWGrowth_Example
//
//  Created by Steven Grosmark on 4/15/19.
//  Copyright © 2019 Weight Watchers International. All rights reserved.
//

import UIKit

/// Where should a new UIViewController go?
enum FlowContext {
    
    /// Present the new UIViewController as a modal
    case presented(from: WeakRef<UIViewController>, containment: Containment)
    
    enum Containment {
        case none
        case navigation(WeakRef<UINavigationController>)
    }
    
    /// Push the new UIViewController onto a navigation stack
    case pushed(in: WeakRef<UINavigationController>)
    
    /// Set the new UIViewController as the root controller
    case root(RootContainer, containment: Containment)
    
    // UIWindow, UINavigationController
    enum RootContainer {
        case window(WeakRef<UIWindow>)
        case navigation(WeakRef<UINavigationController>)
        case tab(WeakRef<UITabBarController>, Int)
    }
    
    final class WeakRef<T: AnyObject> {
        weak var value: T?
        init(_ value: T?) {
            self.value = value
        }
    }
    
}

/// Conveniences for creating contexts
extension FlowContext {
    
    /// Present the new UIViewController as a modal, wrapping it in a UINavigationController first
    static func presented(from controller: UIViewController) -> FlowContext {
        return .presented(from: WeakRef(controller), containment: .navigation)
    }
    
    /// Set the new UIViewController as the root controller of a UIWindow.
    /// By default the new controller will be wrapped in a UINavigationController first.
    static func root(of window: UIWindow, containment: Containment = .navigation) -> FlowContext {
        return .root(.window(WeakRef(window)), containment: containment)
    }
    
    /// Set the new UIViewController as the root controller of a UINavigationController
    static func root(of navController: UINavigationController) -> FlowContext {
        return .root(.navigation(WeakRef(navController)), containment: .none)
    }
    
    /// Set the new UIViewController as the root controller of a UITabBarController.
    /// By default the new controller will be wrapped in a UINavigationController first.
    static func root(of tabBarController: UITabBarController, at index: Int, containment: Containment = .navigation) -> FlowContext {
        return .root(.tab(WeakRef(tabBarController), index), containment: containment)
    }
}

extension FlowContext.Containment {
    
    /// Shorthand for .navigation(nil)
    static var navigation: FlowContext.Containment { return .navigation(FlowContext.WeakRef(nil)) }
    
    internal func create(with controller: UIViewController, presentable: Bool) -> UIViewController {
        switch self {
        case .none: return controller
        case .navigation(let navController):
            if let navController = navController.value {
                navController.set(rootViewController: controller, animated: false)
                return navController
            }
            fatalError()
//            if presentable {
//                return PresentableNavigationViewController.make(withRootViewController: controller)
//            }
//            return CustomBarTintNavigationController(rootViewController: controller)
            //            let navController: UINavigationController = navController ?? UINavigationController()
            //            navController.set(rootViewController: controller, animated: false)
            //            return navController
        }
    }
}

extension UINavigationController {
    func set(rootViewController: UIViewController, animated: Bool) {
        self.setViewControllers([rootViewController], animated: animated)
    }
}

extension FlowContext {
    
    /// Place a new UIViewController in the context
    func place(_ controller: UIViewController) {
        switch self {
            
        case .presented(let fromViewController, let containment):
            let presentableController = containment.create(with: controller, presentable: true)
            fromViewController.value?.present(presentableController, animated: true)
            
        case .pushed(let inNavigationController):
            inNavigationController.value?.pushViewController(controller, animated: true)
            
        case .root(let target, let containment):
            let containedController = containment.create(with: controller, presentable: false)
            switch target {
                
            case .window(let window):
                // in wwmobile, use a transition
                fatalError()
//                window.value?.setRootViewController(containedController, with: .crossfade)
                //window.rootViewController = containedController
                
            case .navigation(let navController):
                navController.value?.setViewControllers([containedController], animated: true)
                
            case .tab(let tabsController, let index):
                guard let tabsController = tabsController.value else { return }
                var controllers = tabsController.viewControllers ?? []
                if index < controllers.count {
                    controllers[index] = containedController
                }
                else {
                    controllers.append(containedController)
                }
                tabsController.setViewControllers(controllers, animated: true)
            }
        }
    }
    
    func placedController() -> UIViewController? {
        switch self {
            
        case .presented(let fromViewController, _):
            return fromViewController.value?.presentedViewController
            
        case .pushed(let inNavigationController):
            return inNavigationController.value?.topViewController
            
        case .root(let target, _):
            switch target {
                
            case .window(let window):
                return window.value?.rootViewController
                
            case .navigation(let navController):
                return navController.value?.viewControllers.first
                
            case .tab(let tabsController, let index):
                var controllers = tabsController.value?.viewControllers ?? []
                if index >= 0 && index < controllers.count {
                    return controllers[index]
                }
            }
        }
        return nil
    }
    
    /// Remove a placed UIViewController from the context.
    /// Makes assumptions about what was placed!
    func remove() {
        switch self {
            
        case .presented(let fromController, _):
            fromController.value?.presentedViewController?.dismiss(animated: true)
            
        case .pushed(let navController):
            navController.value?.popViewController(animated: true)
            
        case .root:
            print("Warning: FlowContext can't remove a root controller")
        }
    }
}

extension FlowContext {
    
    func nextPresented(containment: Containment = .navigation) -> FlowContext? {
        return .presented(fromContext: self, containment: containment)
    }
    
    func nextPushed() -> FlowContext? {
        return .pushed(fromContext: self)
    }
    
    /// Construct a `presented` flow context from another context
    static func presented(fromContext: FlowContext, containment: Containment = .navigation) -> FlowContext? {
        guard let controller = targetController(fromContext) else { return nil }
        return .presented(from: WeakRef(controller), containment: containment)
    }
    
    /// Construct a `pushed` flow context from another context
    static func pushed(fromContext: FlowContext) -> FlowContext? {
        guard let controller = targetController(fromContext) as? UINavigationController else { return nil }
        return .pushed(in: WeakRef(controller))
    }
    
    /// Retrieve the `placed`, or `target` view controller from a flow context
    private static func targetController(_ fromContext: FlowContext) -> UIViewController? {
        switch fromContext {
        case .presented(let fromController, _):
            return fromController.value?.presentedViewController
        case .pushed(let navController):
            return navController.value
        case .root(let container, _):
            switch container {
            case .window(let window):
                return window.value?.rootViewController
            case .navigation(let navController):
                return navController.value
            case .tab(let tabsController, let index):
                guard let tabs = tabsController.value?.viewControllers, index >= 0, index < tabs.count else {
                    return nil
                }
                return tabs[index]
            }
        }
    }
    
}
