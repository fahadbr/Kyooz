//
//  NSErrorExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension NSError : KyoozErrorProtocol {
	
	var errorDescription:String {
		return localizedDescription
	}
	
}