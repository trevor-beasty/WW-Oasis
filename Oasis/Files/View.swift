//
//  View.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/29/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol ViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

public protocol ViewType {
    associatedtype Definition: ViewDefinition
    
    typealias ViewState = Definition.ViewState
    typealias ViewAction = Definition.ViewAction
    typealias ViewStore = AnyViewStore<ViewState, ViewAction>
    
    init(viewStore: ViewStore)
}
