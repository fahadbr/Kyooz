//
//  EnumNameDescriptable.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/26/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

//Add this to enums so that the enum name can be returned as a string representation using
//the variable 'name'
protocol EnumNameDescriptable {
    var name:String { get }
}

extension EnumNameDescriptable {
    var name:String {
        return "\(self)"
    }
}