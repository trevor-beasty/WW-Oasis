//
//  AppDelegate.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let window = window else { fatalError() }
        let windowPlacer = WindowPlacer(WeakBox<UIWindow>(window))
        let myDayFlow = MyDayFlow()
        myDayFlow.start(windowPlacer.asPlacer())
        return true
    }
    
}

