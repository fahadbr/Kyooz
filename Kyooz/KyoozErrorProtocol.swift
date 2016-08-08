//
//  KyoozErrorProtocol.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol KyoozErrorProtocol : Error {
	
	var errorDescription:String { get }
	
}

struct KyoozError : KyoozErrorProtocol {
    let errorDescription:String
}


