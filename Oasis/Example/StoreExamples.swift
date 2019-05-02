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
        let prefixes = ["red", "orange", "blue"]
        let items = prefixes.map({
            return Search.Item.init(id: "", name: $0 + " " + (query ?? ""), points: Int.random(in: 0...10))
        })
        completion(.success(items))
    }
    
}

class SearchViewController: UIViewController, ViewType {
    typealias Definition = SearchView
    
    private let viewStore: ViewStore
    
    private let searchBar = UISearchBar()
    private let itemsTable = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    private weak var alertController: UIAlertController?
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewStore.dispatchAction(.viewWillAppear)
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
        
        func setUpItemsTable() {
            itemsTable.dataSource = self
            itemsTable.delegate = self
            itemsTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        }
        
        func setUpSearchBar() {
            searchBar.delegate = self
        }
        
        setUpConstraints()
        setUpItemsTable()
        setUpSearchBar()
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
        
        viewStore.bind(\.error) { [weak self] (_, error) in
            if let error = error {
                if self?.alertController == nil {
                    self?.showError(error)
                }
            }
            else {
                if let alertController = self?.alertController {
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        }
        
    }
    
    private func showError(_ error: String) {
        let alertController = UIAlertController(title: error, message: nil, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { [viewStore] (_) in
            viewStore.dispatchAction(.didAcknowledgeError)
        }
        alertController.addAction(continueAction)
        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }
    
}

extension SearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewStore.viewState.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        let item = viewStore.viewState.items[indexPath.row]
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = String(item.points)
        return cell
    }
    
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewStore.viewState.items[indexPath.row]
        viewStore.dispatchAction(.didSelectItem(item))
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewStore.dispatchAction(.didUpdateSearchText(searchText))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewStore.dispatchAction(.didPressClear)
    }
    
}

class SearchScreen: Screen<SearchStore, SearchViewController> {
    
    override static func mapState(_ state: State) -> ViewState {
        let error: String?
        switch state.phase {
        case .error(message: let message): error = message
        case .idle, .searching: error = nil
        }
        return ViewState(isLoading: state.phase == .searching, error: error, items: state.items, searchText: state.searchText)
    }
    
    override static func mapViewAction(_ viewAction: ViewAction) -> Action {
        return viewAction
    }
    
}

class TapToSearchFlow: ScreenFlow<None, UINavigationController> {
    
    private weak var navigationController: UINavigationController?
    private var textModule: TextModule?
    
    override func start(with screenPlacer: ScreenPlacer<UINavigationController>) throws {
        let tap = assembleTap()
        self.navigationController = try screenPlacer.place(tap)
    }
    
    private func assembleTap() -> UIViewController {
        let textController = TextController(color: .blue, text: "Tap to search")
        let textModule = TextModule(wrapping: textController)
        
        textModule.observeOutput() { [weak self] output in
            switch output {
            case .didTap:
                guard let strongSelf = self else { return }
                let search = strongSelf.assembleSearch()
                strongSelf.navigationController?.pushViewController(search, animated: true)
            }
        }
        
        self.textModule = textModule
        return textController
    }
    
    private func assembleSearch() -> UIViewController {
        let searchScreen = SearchScreen.init(initialState: .init(searchText: nil, items: [], phase: .idle, viewDidAppear: false))
        searchScreen.store.bind(self)
        
        searchScreen.store.observeStatefulOutput() { [weak self] (output, _) in
            switch output {
            case .didSelectItem(let item):
                guard let strongSelf = self, let textModule = strongSelf.textModule, let textController = textModule.view else { return }
                textModule.handleAction(.showText(item.name))
                strongSelf.navigationController?.popToViewController(textController, animated: true)
            }
        }
        
        return searchScreen.viewController
    }
    
}
