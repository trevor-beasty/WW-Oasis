//
//  StoreExamples.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/29/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

enum Search: StoreDefinition {
    
    struct State: Equatable {
        var searchText: String?
        var items: [Item]
        var phase: Phase
        var viewDidAppear: Bool
        
        enum Phase: Equatable {
            case idle
            case searching
            case error(message: String)
        }
        
    }
    
    enum Action: Equatable {
        case didUpdateSearchText(String?)
        case didPressClear
        case didSelectItem(Item)
        case viewWillAppear
        case didAcknowledgeError
    }
    
    enum Output: Equatable {
        case didSelectItem(Item)
    }
    
    struct Item: Equatable {
        let id: String
        let name: String
        let points: Int
    }
    
}

enum SearchView: ViewDefinition {
    
    struct ViewState: Equatable {
        let isLoading: Bool
        let error: String?
        let items: [Search.Item]
        let searchText: String?
    }
    
    typealias ViewAction = Search.Action
    
}

class SearchStore: Store<Search> {
    
    var searchService: SearchServiceProtocol = SearchService()
    
    override func handleAction(_ action: Search.Action) {
        switch action {
        case .didPressClear:
            batchUpdate({ $0.searchText = nil })
            search(nil)
        
        case .didSelectItem(let item):
            output(.didSelectItem(item))
            
        case .didUpdateSearchText(let searchText):
            batchUpdate({ $0.searchText = searchText })
            search(searchText)
            
        case .viewWillAppear:
            handleViewWillAppear()
            
        case .didAcknowledgeError:
            update({ $0.phase = .idle })
        }
    }
    
    private func search(_ searchText: String?) {
        update({
            $0.phase = .searching
        })
        searchService.search(searchText) { [weak self] (searchItemsResult) in
            guard let strongSelf = self else { return }
            switch searchItemsResult {
            case .success(let searchItems):
                strongSelf.update({
                    $0.items = searchItems
                    $0.phase = .idle
                })
            case .failure:
                strongSelf.update({
                    $0.items = []
                    $0.phase = .error(message: "Please try again later")
                })
            }
        }
    }
    
    private func handleViewWillAppear() {
        if !state.viewDidAppear {
            batchUpdate({ $0.viewDidAppear = true })
            search(state.searchText)
        }
    }
    
}

protocol SearchServiceProtocol: AnyObject {
    func search(_ query: String?, completion: @escaping (Result<[Search.Item]>) -> Void)
}

class SearchService: SearchServiceProtocol {
    
    func search(_ query: String?, completion: @escaping (Result<[Search.Item]>) -> Void) {
        
    }
    
}

class SearchViewController: UIViewController, ViewType {
    typealias Definition = SearchView
    
    private let viewStore: ViewStore
    
    private let searchBar = UISearchBar()
    private let itemsTable = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    required init(viewStore: AnyViewStore<ViewState, ViewAction>) {
        self.viewStore = viewStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bind()
    }
    
    private func setUp() {
        
        func setUpConstraints() {
            [searchBar, itemsTable, activityIndicator].forEach({
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            })
            let constraints = [
                searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                searchBar.leftAnchor.constraint(equalTo: view.leftAnchor),
                searchBar.rightAnchor.constraint(equalTo: view.rightAnchor),
                searchBar.heightAnchor.constraint(equalToConstant: 50),
                itemsTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                itemsTable.leftAnchor.constraint(equalTo: view.leftAnchor),
                itemsTable.rightAnchor.constraint(equalTo: view.rightAnchor),
                itemsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                activityIndicator.leftAnchor.constraint(equalTo: view.leftAnchor),
                activityIndicator.rightAnchor.constraint(equalTo: view.rightAnchor),
                activityIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        
        setUpConstraints()
    }
    
    private func bind() {
        
        viewStore.bind(\.isLoading) { [activityIndicator] (_, isLoading) in
            if isLoading {
                if !activityIndicator.isAnimating { activityIndicator.startAnimating() }
            }
            else {
                if activityIndicator.isAnimating { activityIndicator.stopAnimating() }
            }
        }
        
        viewStore.bind(\.items) { [weak self] (_, _) in
            self?.itemsTable.reloadData()
        }
        
        viewStore.bind(\.searchText) { [searchBar] (_, searchText) in
            searchBar.text = searchText
        }
        
    }
    
    func render(_ viewState: SearchViewController.ViewState) {
        
    }
    
}
