//
//  AppDelegate.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

fileprivate enum Option {
    case searchScreen
    case complexFlow
}

fileprivate let option: Option = .searchScreen

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let window = window else { fatalError() }
        let windowPlacer = ScreenPlacement.makeWindowPlacer(window)
        switch option {
        case .complexFlow:
            let myDayFlow = MyDayFlow()
            try? myDayFlow.start(with: windowPlacer)
            
        case .searchScreen:
            let emptyController = UIViewController()
            let navigationController = try! windowPlacer
                .makeNavigationPlacer(UINavigationController())
                .place(emptyController)
            let placer = navigationController.makePushPlacer()
            let tapToSearchFlow = TapToSearchFlow()
            _ = try! tapToSearchFlow.start(with: placer)
        }

        return true
    }
    
}

