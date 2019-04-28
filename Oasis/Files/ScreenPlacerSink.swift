//
//  ScreenPlacerSink.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/28/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

public enum ScreenPlacement {
    
    public static func makePlacer<Base: AnyObject, NextScreenContext: UIViewController>(_ base: Base, place: @escaping (Base, UIViewController) -> NextScreenContext) -> ScreenPlacer<NextScreenContext> {
        let sink = ScreenPlacerSink<Base, NextScreenContext>.init(.weak(WeakBox(base)), place: place)
        return ScreenPlacer<NextScreenContext>(sink)
    }
    
}

public enum ScreenPlacerBaseError<Base: AnyObject>: Error {
    case nilBase(WeakBox<Base>)
}

public enum ScreenPlacerError: Error {
    case placementExhausted
}

fileprivate class ScreenPlacerSink<Base: AnyObject, NextScreenContext: UIViewController>: ScreenPlacerType {
    typealias Place = (Base, UIViewController) throws -> NextScreenContext
    
    private let base: WeakStrong<Base>
    private let place: Place
    private var didPlace = false
    
    init(_ base: WeakStrong<Base>, place: @escaping Place) {
        self.base = base
        self.place = place
    }
    
    func place(_ viewController: UIViewController) throws -> NextScreenContext {
        guard !didPlace else {
            throw ScreenPlacerError.placementExhausted
        }
        let base: Base
        switch self.base {
        case .strong(let _base):
            base = _base
        case .weak(let weakBox):
            guard let _base = weakBox.boxed else {
                throw ScreenPlacerBaseError<Base>.nilBase(weakBox)
            }
            base = _base
        }
        let nextScreenContext = try place(base, viewController)
        didPlace = true
        return nextScreenContext
    }
    
}

public class ScreenPlacer<NextScreenContext: UIViewController>: ScreenPlacerType {
    
    private let _place: (UIViewController) throws -> NextScreenContext
    
    fileprivate init<ScreenPlacer: ScreenPlacerType>(_ screenPlacer: ScreenPlacer) where ScreenPlacer.NextScreenContext == NextScreenContext {
        self._place = screenPlacer.place
    }
    
    public func place(_ viewController: UIViewController) throws -> NextScreenContext {
        return try _place(viewController)
    }
    
}
