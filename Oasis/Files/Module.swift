//
//  Module.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol ModuleDefinition {
    associatedtype Action
    associatedtype Output
}

public protocol ModuleProtocol: ModuleDefinition {
    func handleAction(_ action: Action)
    func observeOutput(_ observer: @escaping (Output) -> Void)
}

open class Module<Action, Output>: ModuleProtocol {
    
    private var outputObservers: [(Output) -> Void] = []
    
    public init() { }
    
    open func handleAction(_ action: Action) {
        return lassoAbstractMethod()
    }
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservers.append(observer)
    }
    
    public func output(_ output: Output) {
        executeOnMainThread { [weak self] in
            self?.outputObservers.forEach({ $0(output) })
        }
    }
    
}
