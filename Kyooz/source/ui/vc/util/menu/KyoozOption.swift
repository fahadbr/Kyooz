//
//  KyoozOption.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol KyoozOption {
    
    var title: String { get }
    var info: String? { get }
    var action: (()->())? { get }
    var highlighted: Bool { get }

}

struct KyoozMenuAction : KyoozOption {
    
    let title: String
    let info: String?
    let action: (()->())?
    let highlighted: Bool
    
    init(title: String,
         info: String? = nil,
         highlighted: Bool = false,
         action: (()->())? = nil) {
        self.title = title
        self.info = info
        self.highlighted = highlighted
        self.action = action
    }
}

