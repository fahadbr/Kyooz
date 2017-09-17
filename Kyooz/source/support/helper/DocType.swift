//
//  DocumentType.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

enum DocType : EnumNameDescriptable {
	case html, rtf
	
	var attributeDictionary:[NSAttributedString.DocumentReadingOptionKey:Any] {
		let attributeName: NSAttributedString.DocumentType
		switch self {
		case .html:
			attributeName = .html
		case .rtf:
			attributeName = .rtf
		}
		
		return [NSAttributedString.DocumentReadingOptionKey.documentType:attributeName]
	}
}
