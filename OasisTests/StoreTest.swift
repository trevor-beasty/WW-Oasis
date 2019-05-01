//
//  StoreTest.swift
//  OasisTests
//
//  Created by Trevor Beasty on 5/1/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import Oasis

public typealias StoreAssertion<T> = (T) -> Bool

fileprivate func storeAssert<T>(_ assertions: [StoreAssertion<T>], on values: [T], file: StaticString = #file, line: UInt = #line) {
    guard values.count == assertions.count else {
        XCTFail("bad count - expected \(assertions.count), realized \(values.count)", file: file, line: line)
        return
    }
    for (i, assertion) in assertions.enumerated() {
        XCTAssertTrue(assertion(values[i]), file: file, line: line)
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
    
    public func assert(when action: Store.Action, stateAssertions: [StoreAssertion<Store.State>]? = nil, outputAssertions: [StoreAssertion<Store.Output>]? = nil, file: StaticString = #file, line: UInt = #line) {
        store.handleAction(action)
        if let stateAssertions = stateAssertions {
            storeAssert(stateAssertions, on: self.states, file: file, line: line)
        }
        if let outputAssertions = outputAssertions {
            storeAssert(outputAssertions, on: self.outputs, file: file, line: line)
        }
    }
    
    open func configureInjections(for store: Store) {
        return lassoAbstractMethod()
    }
    
}

public class StoreTestGenerator<Store: StoreType> {
    
    private let testCase: XCTestCase
    private let configureInjections: (Store) -> Void
    
    public init(_ testCase: XCTestCase, configureInjections: @escaping (Store) -> Void) {
        self.testCase = testCase
        self.configureInjections = configureInjections
    }
    
    public func given(initialState: Store.State) -> Given {
        let makeTestStore: () -> TestStore<Store> = {
            return TestStore<Store>.init(initialState, configureInjections: self.configureInjections, allowExhaustion: self.testCase.allowMainQueueExhaustion)
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
        
        public func then(stateAssertions: [StoreAssertion<Store.State>]? = nil, outputAssertions: [StoreAssertion<Store.Output>]? = nil, file: StaticString = #file, line: UInt = #line) {
            let testStore = given.makeTestStore()
            testStore.assert(when: toSend, stateAssertions: stateAssertions, outputAssertions: outputAssertions, file: file, line: line)
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
