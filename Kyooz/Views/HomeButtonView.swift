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
	var scale:CGFloat = 0.35 {
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
	var roofHeightProportion:CGFloat = 0.4
	
	@IBInspectable
	var sideExtensionProportion:CGFloat = 0.13
	
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
		let insetRect = CGRectInset(rect, inset * rect.width, inset * rect.height)
		
		let smallerSide = min(insetRect.height, insetRect.width)
		let roofHeight = smallerSide * roofHeightProportion
		let baseSide = smallerSide - roofHeight
        let baseWidth = baseSide * 1.4
		
		let baseRect = CGRect(x: insetRect.midX - baseWidth/2, y: insetRect.origin.y + roofHeight, width: baseWidth, height: baseSide)
        let basePath = UIBezierPath()
        basePath.moveToPoint(baseRect.origin)
        basePath.addLineToPoint(CGPoint(x: baseRect.origin.x, y: baseRect.maxY))
        basePath.addLineToPoint(CGPoint(x: baseRect.maxX, y: baseRect.maxY))
        basePath.addLineToPoint(CGPoint(x: baseRect.maxX, y: baseRect.origin.y))
        
		let slope = roofHeight/(baseWidth/2)
		
		let xOffset = smallerSide * sideExtensionProportion
		let yOffset = xOffset * slope
		
		basePath.moveToPoint(CGPoint(x: baseRect.origin.x - xOffset, y: baseRect.origin.y + yOffset))
		basePath.addLineToPoint(CGPoint(x: insetRect.midX, y: insetRect.origin.y))
		basePath.addLineToPoint(CGPoint(x: baseRect.maxX + xOffset, y: baseRect.origin.y + yOffset))
		
        basePath.lineCapStyle = .Round
        basePath.lineWidth = smallerSide * 0.05
//        basePath.applyTransform(CGAffineTransformMakeTranslation(inset * rect.width * 0.6, 0))
		basePath.stroke()
		
	}
	
}
