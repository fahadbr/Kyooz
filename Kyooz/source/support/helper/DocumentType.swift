//
//  DocumentType.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

enum DocumentType : EnumNameDescriptable {
	case html, rtf
	
	var attributeDictionary:[String:Any] {
		let attributeName:String
		switch self {
		case .html:
			attributeName = NSHTMLTextDocumentType
		case .rtf:
			attributeName =  NSRTFTextDocumentType
		}
		
		return [NSDocumentTypeDocumentAttribute:attributeName]
	}
}
