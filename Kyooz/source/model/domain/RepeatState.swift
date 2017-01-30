//
//  RepeatState.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/25/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

enum RepeatState:Int, EnumNameDescriptable {
    case off
    case all
    case one
    
    var nextState:RepeatState {
        return RepeatState(rawValue: self.rawValue + 1) ?? .off
    }
    
}
