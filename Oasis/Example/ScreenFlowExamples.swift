//
//  ScreenFlowExamples.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/27/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

enum OnboardingAOutput {
    case didFinish
}

class FoodOnboardingFlow: ScreenFlow<OnboardingAOutput, UINavigationController> {
    
    private weak var navigationController: UINavigationController?
    
    override func start(with screenPlacer: ScreenPlacer<UINavigationController>) throws {
        let initialController = assembleController(0)
        navigationController = try screenPlacer.place(initialController)
    }
    
    private func assembleController(_ rank: Int) -> UIViewController {
        let color: UIColor
        let text: String
        switch rank {
        case 0:
            color = .blue
            text = "Do you eat food?"
        case 1:
            color = .purple
            text = "We have magical powers that make some foods zero calories!"
        case 2:
            color = .darkGray
            text = "So... you're in! Let's go eat some grapes!"
        default:
            fatalError()
        }
        let controller = TextController(color: color, text: text)
        controller.bind(self)
        
        controller.onDidTap = { [weak self] in
            guard let strongSelf = self else { return }
            switch rank {
            case 0, 1:
                let nextController = strongSelf.assembleController(rank + 1)
                strongSelf.navigationController?.pushViewController(nextController, animated: true)
            case 2:
                strongSelf.output(.didFinish)
            default:
                fatalError()
            }
        }
        
        return controller
    }
    
}

class MyDayFlow: ScreenFlow<None, UIViewController> {
    
    private weak var tabBarController: UITabBarController?
    
    override func start(with screenPlacer: ScreenPlacer<UIViewController>) throws {
        let tabBarController = UITabBarController()
        
        let tabBarPlacers = screenPlacer.makeTabBarPlacers(tabBarController, tabsCount: 2)
        
        let tabBarPlacer0 = tabBarPlacers[0].makeNavigationPlacer(UINavigationController())
        let foodOnboardingFlow = FoodOnboardingFlow()
        try foodOnboardingFlow.start(with: tabBarPlacer0)
        
        let controller1 = TextController(color: .orange, text: "Apple's love to dance!")
        _ = try tabBarPlacers[1].place(controller1)
        
        self.tabBarController = tabBarController
    }
    
}

class TextController: UIViewController, ObjectBindable {
    
    let objectBinder = ObjectBinder()
    var onDidTap: () -> Void = { }
    
    let color: UIColor
    let text: String
    
    let label = UILabel()
    
    init(color: UIColor, text: String) {
        self.color = color
        self.text = text
        super.init(nibName: nil, bundle: nil)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func loadView() {
        label.text = text
        label.backgroundColor = color
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.isUserInteractionEnabled = true
        self.view = label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func setUp() {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didTap))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func didTap() {
        onDidTap()
    }
    
    func showText(_ text: String?) {
        label.text = text
    }
    
}

enum TextControllerAction: Equatable {
    case showText(String?)
}

enum TextControllerOutput: Equatable {
    case didTap
}

class TextControllerModule: Module<TextControllerAction, TextControllerOutput> {
    
    let textController: TextController
    
    init(color: UIColor, text: String) {
        self.textController = TextController(color: color, text: text)
        super.init()
        
        textController.onDidTap = { [weak self] in
            self?.output(.didTap)
        }
    }
    
    override func handleAction(_ action: TextControllerAction) {
        switch action {
        case .showText(let text):
            textController.showText(text)
        }
    }
    
}
