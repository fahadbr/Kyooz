//
//  HomeButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/21/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class HomeButtonView : UIButton {
	
	@IBInspectable
	var scale:CGFloat = 0.8 {
		didSet {
			setNeedsDisplay()
		}
	}
	
	var color:UIColor = ThemeHelper.defaultFontColor {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override var highlighted:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override var enabled:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	@IBInspectable
	var roofHeightProportion:CGFloat = 0.25
	
	@IBInspectable
	var sideExtensionLength:CGFloat = 10
	
	override func drawRect(rect: CGRect) {
		if !enabled {
			UIColor.darkGrayColor().setFill()
			UIColor.darkGrayColor().setStroke()
		} else if highlighted {
			if let highlightColor = titleColorForState(.Highlighted) {
				highlightColor.setFill()
				highlightColor.setStroke()
			} else {
				UIColor.darkGrayColor().setFill()
				UIColor.darkGrayColor().setStroke()
			}
		} else {
			color.setFill()
			color.setStroke()
		}
		
		let inset:CGFloat = (1 - scale)/2
		let insetRect = CGRectInset(rect, inset * rect.width, inset)
		
		let smallerSide = min(insetRect.height, insetRect.width)
		let roofHeight = smallerSide * roofHeightProportion
		let baseSide = smallerSide - roofHeight
		
		let baseRect = CGRect(x: insetRect.midX - baseSide/2, y: insetRect.origin.y + roofHeight, width: baseSide, height: baseSide)
		let basePath = UIBezierPath(rect: baseRect)
		let slope = roofHeight/(baseSide/2)
		
		let xOffset = sideExtensionLength
		let yOffset = xOffset * slope
		
		basePath.moveToPoint(CGPoint(x: baseRect.origin.x - xOffset, y: baseRect.origin.y + yOffset))
		basePath.addLineToPoint(CGPoint(x: insetRect.midX, y: insetRect.origin.y))
		basePath.addLineToPoint(CGPoint(x: baseRect.maxX + xOffset, y: baseRect.origin.y + yOffset))
		
		basePath.stroke()
		
	}
	
}
