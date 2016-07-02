//
//  UITextViewExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

extension UITextView {
	
	convenience init(fileName:String, documentType:DocumentType) throws {
		self.init()
		editable = false
		textColor = ThemeHelper.defaultFontColor
		attributedText = try NSAttributedString(fileName: fileName, documentType: documentType)
	}
	
}
