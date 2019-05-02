//
//  ViewModule.swift
//  Oasis
//
//  Created by Trevor Beasty on 5/2/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

public class ViewModule<View: UIViewController, Action, Output>: Module<Action, Output> where View: ObjectBindable {
    
    public weak var view: View?
    
    public init(wrapping view: View) {
        super.init()
        attachTo(view)
        view.bind(self)
        self.view = view
    }
    
    open func attachTo(_ view: View) {
        return lassoAbstractMethod()
    }
    
}
