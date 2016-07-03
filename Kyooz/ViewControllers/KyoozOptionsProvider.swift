//
//  KyoozOptionsProvider.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol KyoozOptionsProvider {
    
    var options:[KyoozOption] { get }
    
}

struct BasicKyoozOptionsProvider : KyoozOptionsProvider {
    let options:[KyoozOption]
}

extension BasicKyoozOptionsProvider {
    init(options:KyoozOption...) {
        self.options = options
    }
}
