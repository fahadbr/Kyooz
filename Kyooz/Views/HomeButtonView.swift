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
	
	override var isHighlighted:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override var isEnabled:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	@IBInspectable
	var roofHeightProportion:CGFloat = 0.4
	
	@IBInspectable
	var sideExtensionProportion:CGFloat = 0.13
	
	override func draw(_ rect: CGRect) {
		if !isEnabled {
			UIColor.darkGray.setFill()
			UIColor.darkGray.setStroke()
		} else if isHighlighted {
			if let highlightColor = titleColor(for: .highlighted) {
				highlightColor.setFill()
				highlightColor.setStroke()
			} else {
				UIColor.darkGray.setFill()
				UIColor.darkGray.setStroke()
			}
		} else {
			color.setFill()
			color.setStroke()
		}
		
		let inset:CGFloat = (1 - scale)/2
		let insetRect = rect.insetBy(dx: inset * rect.width, dy: inset * rect.height)
		
		let smallerSide = min(insetRect.height, insetRect.width)
		let roofHeight = smallerSide * roofHeightProportion
		let baseSide = smallerSide - roofHeight
        let baseWidth = baseSide * 1.4
		
		let baseRect = CGRect(x: insetRect.midX - baseWidth/2, y: insetRect.origin.y + roofHeight, width: baseWidth, height: baseSide)
        let basePath = UIBezierPath()
        basePath.move(to: baseRect.origin)
        basePath.addLine(to: CGPoint(x: baseRect.origin.x, y: baseRect.maxY))
        basePath.addLine(to: CGPoint(x: baseRect.maxX, y: baseRect.maxY))
        basePath.addLine(to: CGPoint(x: baseRect.maxX, y: baseRect.origin.y))
        
		let slope = roofHeight/(baseWidth/2)
		
		let xOffset = smallerSide * sideExtensionProportion
		let yOffset = xOffset * slope
		
		basePath.move(to: CGPoint(x: baseRect.origin.x - xOffset, y: baseRect.origin.y + yOffset))
		basePath.addLine(to: CGPoint(x: insetRect.midX, y: insetRect.origin.y))
		basePath.addLine(to: CGPoint(x: baseRect.maxX + xOffset, y: baseRect.origin.y + yOffset))
		
        basePath.lineCapStyle = .round
        basePath.lineWidth = smallerSide * 0.05
//        basePath.applyTransform(CGAffineTransformMakeTranslation(inset * rect.width * 0.6, 0))
		basePath.stroke()
		
	}
	
}
