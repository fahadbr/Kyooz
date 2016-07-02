//
//  KyoozOptionsHeaderProvider.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol KyoozOptionsHeaderProvider {
	
	func headerView(withMaxSize maxSize:CGSize) -> UIView
	
}

struct KyoozOptionsTextViewHeaderProvider : KyoozOptionsHeaderProvider {
	
	let textView:UITextView
	
	init(fileName:String, documentType:DocumentType) throws {		
		self.textView = try UITextView(fileName: fileName, documentType: documentType)
	}
	
	func headerView(withMaxSize maxSize: CGSize) -> UIView {
		textView.frame.size = maxSize
		return textView
	}

}