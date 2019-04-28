//
//  ScreenPlacing.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

public protocol ScreenPlacerType: AnyObject {
    associatedtype NextScreenContext: UIViewController
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext
}

extension ScreenPlacerType {
    
    public func makeTabBarPlacers(_ tabBarController: UITabBarController, tabsCount: Int) -> [ScreenPlacer<UITabBarController>] {
        
        var placingBuffer: [UIViewController?] = Array<UIViewController?>.init(repeating: nil, count: tabsCount) {
            didSet {
                let placed = placingBuffer.compactMap({ $0 })
                guard placed.count == tabsCount else { return }
                tabBarController.setViewControllers(placed, animated: false)
                _ = try? self.place(tabBarController)
            }
        }
        
        return (0..<tabsCount).map({ index -> ScreenPlacer<UITabBarController> in
            return ScreenPlacement.makePlacer(tabBarController, isEmbedding: true) { tabBarController, toPlace in
                placingBuffer[index] = toPlace
                return tabBarController
            }
        })

    }
    
    public func makeNavigationPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<UINavigationController> {
        return ScreenPlacement.makePlacer(navigationController, isEmbedding: true) { navigationController, toPlace in
            navigationController.viewControllers = [toPlace]
            _ = try? self.place(navigationController)
            return navigationController
        }
    }
    
}

extension ScreenPlacement {
    
    public static func makeWindowPlacer(_ window: UIWindow) -> ScreenPlacer<UIViewController> {
        return makePlacer(window) { window, toPlace in
            window.rootViewController = toPlace
            return toPlace
        }
    }
    
}

extension UIViewController {
    
    public func makeModalPlacer() -> ScreenPlacer<UIViewController> {
        return ScreenPlacement.makePlacer(self) { presenting, toPlace in
            presenting.present(toPlace, animated: true, completion: nil)
            return toPlace
        }
    }
    
    public func makeNavigationEmbeddedModalPlacer(_ navigationController: UINavigationController) -> ScreenPlacer<UINavigationController> {
        return makeModalPlacer()
            .makeNavigationPlacer(navigationController)
    }
    
}

extension UINavigationController {
    
    public func makePushPlacer() -> ScreenPlacer<UINavigationController> {
        return ScreenPlacement.makePlacer(self) { navigationController, toPlace in
            navigationController.pushViewController(toPlace, animated: true)
            return navigationController
        }
    }
    
}
