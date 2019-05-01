//
//  SearchStoreTests.swift
//  OasisTests
//
//  Created by Trevor Beasty on 5/1/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import Oasis

class SearchStoreTests: XCTestCase {
    
    lazy var test = StoreTest<SearchStore>(self, defaultState: defaultState) { store in
        store.searchService = self.mockSearchService
    }
    
    var defaultState: SearchStore.State {
        return SearchStore.State.init(searchText: nil, items: [], phase: .idle, viewDidAppear: true)
    }
    
    var mockSearchService: MockSearchService!
    
    override func setUp() {
        super.setUp()
        mockSearchService = MockSearchService()
    }
    
    override func tearDown() {
        mockSearchService = nil
        super.tearDown()
    }
    
    func test_GivenItems_SelectItem_OutputsSelectItem() {
        let items: [Search.Item] = [
            Search.Item.init(id: "", name: "foo", points: 0),
            Search.Item.init(id: "", name: "bar", points: 1)
        ]
        
        test
            .given(initialState: { $0.items = items })
            .when(.didSelectItem(items[1]))
            .then(
                outputAssertions: [{ XCTAssertEqual($0, .didSelectItem(items[1])) }]
        )
    }
    
    func test_GivenViewHasNotAppeared_ViewWillAppear_Searches() {
        let items: [Search.Item] = [
            Search.Item.init(id: "", name: "foo", points: 0),
            Search.Item.init(id: "", name: "bar", points: 1)
        ]
        mockSearchService.onSearch = { _, completion in
            completion(.success(items))
        }
        
        test
            .given(initialState: { $0.viewDidAppear = false })
            .when(.viewWillAppear)
            .then(
                stateAssertions: [
                    {
                        XCTAssertEqual($0.phase, .searching)
                        XCTAssertEqual($0.viewDidAppear, true)
                    },
                    {
                        XCTAssertEqual($0.phase, .idle)
                        XCTAssertEqual($0.items, items)
                    }
                ]
        )
    }
    
}

class MockSearchService: SearchServiceProtocol {
    
    var onSearch: (String?, @escaping (Result<[Search.Item]>) -> Void) -> Void = { (_, _) in return }
    
    func search(_ query: String?, completion: @escaping (Result<[Search.Item]>) -> Void) {
        onSearch(query, completion)
    }
    
}
