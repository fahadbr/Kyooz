//
//  MenuDotsView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class MenuDotsView: UIButton {
    
    @IBInspectable
    var color:UIColor = ThemeHelper.defaultTintColor{
        didSet {
            setNeedsDisplay()
        }
    }
	
	@IBInspectable
	var position:CGFloat = 0.75
    
    var scale:CGFloat = 0.24 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var isHighlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        let colorToUse:UIColor
        if !isEnabled {
            colorToUse = UIColor.darkGray
        } else if isHighlighted {
            colorToUse = ThemeHelper.defaultVividColor
        } else {
            colorToUse = color
        }
        
        colorToUse.setStroke()
        colorToUse.setFill()
        
        let rectToUse = rect.insetBy(dx: 0, dy: ((1 - scale)/2) * rect.height)
        
        let minX = rect.origin.x

        let size = rectToUse.height * 0.35
        let circlePath = UIBezierPath()
        circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: rectToUse.minY, width: size, height: size)))
        
        circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: rectToUse.midY, width: size, height: size)))
        
        circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: rectToUse.maxY, width: size, height: size)))
        
        let translationAmount = -size/2
        circlePath.apply(CGAffineTransform(translationX: translationAmount + rect.width * position, y: translationAmount))
        circlePath.fill()
    }

}
