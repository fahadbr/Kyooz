//
//  WhatsNewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit



struct KyoozOptionsTextViewHeaderProvider  {
	
	let textView:UITextView
	
	init(fileName:String, documentType:DocumentType) throws {		
		self.textView = try UITextView(fileName: fileName, documentType: documentType)
	}
	
	func headerView(with sizeConstraint: SizeConstraint) -> UIView {
		textView.frame.size = sizeConstraint.maxSize
		return textView
	}

}

