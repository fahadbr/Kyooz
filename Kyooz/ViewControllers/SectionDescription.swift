//
//  SectionDescription.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

@objc protocol SectionDescription {
    var name:String { get }
    var count:Int { get }
}

class SectionDTO : SectionDescription {
    @objc let name:String
    @objc let count:Int
    init(name:String, count:Int) {
        self.name = name
        self.count = count
    }
}
