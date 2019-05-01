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
    
    lazy var testGenerator = StoreTestGenerator<SearchStore>(self) { store in
        store.searchService = self.mockSearchService
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
        
        testGenerator
            .given(initialState: .init(searchText: nil, items: items, phase: .idle, viewDidAppear: true))
            .when(.didSelectItem(items[1]))
            .then(
                outputAssertions: [{ $0 == .didSelectItem(items[0]) }]
        )
    }
    
//    func test_GivenViewHasNotAppeared_ViewWillAppear_Searches() {
//        // given
//        let items: [Search.Item] = [
//            Search.Item.init(id: "", name: "foo", points: 0),
//            Search.Item.init(id: "", name: "bar", points: 1)
//        ]
//        mockSearchService.onSearch = { _, completion in
//            completion(.success(items))
//        }
//        begin(with: .init(searchText: nil, items: [], phase: .idle, viewDidAppear: false))
//        print("hello")
//
//        // when, then
//        assert(
//            when: .viewWillAppear,
//            stateAssertions: [
//                {
//                    return $0.phase == .error(message: "")
//                    && $0.viewDidAppear == true
//                },
//                {
//                    return $0.phase == .idle
//                    && $0.items == items
//                }
//            ]
//        )
//    }
    
}

class MockSearchService: SearchServiceProtocol {
    
    var onSearch: (String?, @escaping (Result<[Search.Item]>) -> Void) -> Void = { (_, _) in return }
    
    func search(_ query: String?, completion: @escaping (Result<[Search.Item]>) -> Void) {
        onSearch(query, completion)
    }
    
}
