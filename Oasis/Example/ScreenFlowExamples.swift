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

class OnboardingA: ScreenFlow<OnboardingAOutput, NavigationContext> {
    
    private weak var navigationController: UINavigationController?
    
    override func start(_ screenPlacer: AnyScreenPlacer<NavigationContext>) {
        let initialController = assembleController(0)
        navigationController = screenPlacer.place(initialController).context
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
            color = .green
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

class TextController: UIViewController, ObjectBindable {
    
    let objectBinder = ObjectBinder()
    var onDidTap: () -> Void = { }
    
    let color: UIColor
    let text: String
    
    init(color: UIColor, text: String) {
        self.color = color
        self.text = text
        super.init(nibName: nil, bundle: nil)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func loadView() {
        let label = UILabel()
        label.text = text
        label.backgroundColor = color
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
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
    
}
