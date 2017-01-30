//
//  SizeConstraint.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import CoreGraphics

struct SizeConstraint {
	
	let maxHeight: CGFloat
	let maxWidth: CGFloat
	let minHeight: CGFloat
	let minWidth: CGFloat
	
}

extension SizeConstraint {

	var maxSize: CGSize {
		return CGSize(width: maxWidth, height: maxHeight)
	}
	
	var minSize: CGSize {
		return CGSize(width: minWidth, height: minHeight)
	}
	
}
