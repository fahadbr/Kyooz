//
//  SizeConstraints.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import CoreGraphics

protocol SizeConstraint {
	
	var maxHeight: CGFloat { get }
	var maxWidth: CGFloat { get }
	var minHeight: CGFloat { get }
	var minWidth: CGFloat { get }
	
}

extension SizeConstraint {

	var maxSize: CGSize {
		return CGSize(width: maxWidth, height: maxHeight)
	}
	
	var minSize: CGSize {
		return CGSize(width: minWidth, height: minHeight)
	}
	
}
