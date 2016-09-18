//
//  ErrorTypeExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension Error  {
	
	var description : String {
		return (self as? KyoozErrorProtocol)?.errorDescription ?? "\(type(of: self))"
	}
	
}
