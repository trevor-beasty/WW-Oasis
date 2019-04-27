//
//  ScreenFlow.swift
//  Oasis
//
//  Created by Trevor Beasty on 4/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import UIKit

class ScreenFlow<Output, ScreenContext: ScreenContextType>: Module<None, Output> {
    
    open func start(_ screenPlacer: AnyScreenPlacer<ScreenContext>) {
        fatalError(abstractMethodMessage)
    }

}
