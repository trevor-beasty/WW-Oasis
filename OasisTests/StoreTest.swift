//
//  StoreTest.swift
//  OasisTests
//
//  Created by Trevor Beasty on 5/1/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import Oasis

public typealias ValueAssertion<T> = (T) -> Void

fileprivate func storeAssert<T>(_ assertions: [ValueAssertion<T>], on values: [T]) {
    guard values.count == assertions.count else {
        XCTFail("bad count - expected \(assertions.count), realized \(values.count)")
        return
    }
    for (i, assertion) in assertions.enumerated() {
        assertion(values[i])
    }
}

public class TestStore<Store: StoreType> {
    
    private let store: Store
    
    private var states: [Store.State] = []
    private var outputs: [Store.Output] = []
    
    private let allowExhaustion: () -> Void

    fileprivate init(_ initialState: Store.State, configureInjections: (Store) -> Void, allowExhaustion: @escaping () -> Void) {
        self.store = Store.init(initialState)
        self.allowExhaustion = allowExhaustion
        configureInjections(store)
        
        store.bind() { (_, newState) in
            self.states.append(newState)
        }
        
        store.observeStatefulOutput { (output, _) in
            self.outputs.append(output)
        }
        
        states = []
        outputs = []
    }
    
    public func assert(when action: Store.Action, stateAssertions: [ValueAssertion<Store.State>]? = nil, outputAssertions: [ValueAssertion<Store.Output>]? = nil) {
        store.handleAction(action)
        if let stateAssertions = stateAssertions {
            storeAssert(stateAssertions, on: self.states)
        }
        if let outputAssertions = outputAssertions {
            storeAssert(outputAssertions, on: self.outputs)
        }
    }
    
    open func configureInjections(for store: Store) {
        return lassoAbstractMethod()
    }
    
}

public class StoreTest<Store: StoreType> {
    
    private let defaultState: Store.State
    private let testCase: XCTestCase
    private let configureInjections: (Store) -> Void
    
    public init(_ testCase: XCTestCase, defaultState: Store.State, configureInjections: @escaping (Store) -> Void) {
        self.defaultState = defaultState
        self.testCase = testCase
        self.configureInjections = configureInjections
    }
    
    public func given(initialState: @escaping (inout Store.State) -> Void) -> Given {
        let makeTestStore: () -> TestStore<Store> = {
            var copy = self.defaultState
            initialState(&copy)
            return TestStore<Store>.init(copy, configureInjections: self.configureInjections, allowExhaustion: self.testCase.allowMainQueueExhaustion)
        }
        return Given(makeTestStore: makeTestStore)
    }
    
    public struct Given {
        internal let makeTestStore: () -> TestStore<Store>
        
        public func when(_ toSend: Store.Action) -> When {
            return When(given: self, toSend: toSend)
        }
    }
    
    public struct When {
        private let given: Given
        private let toSend: Store.Action
        
        internal init(given: Given, toSend: Store.Action) {
            self.given = given
            self.toSend = toSend
        }
        
        public func then(stateAssertions: [ValueAssertion<Store.State>]? = nil, outputAssertions: [ValueAssertion<Store.Output>]? = nil) {
            let testStore = given.makeTestStore()
            testStore.assert(when: toSend, stateAssertions: stateAssertions, outputAssertions: outputAssertions)
        }
    }
    
}

extension XCTestCase {
    
    fileprivate func allowMainQueueExhaustion() {
        let exhausted = expectation(description: "")
        DispatchQueue.main.async {
            exhausted.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}
