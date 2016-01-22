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
    
    override var highlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        var color:UIColor!
        if highlighted {
            if let highlightColor = titleColorForState(.Highlighted) {
                color = highlightColor
            } else {
                color = ThemeHelper.defaultVividColor
            }
        } else {
            color = self.color
        }
        color.setFill()
        
        let rectToUse = CGRectInset(rect, 0.25 * rect.width, 0.38 * rect.height)
        
        let minX = rectToUse.maxX

        let size = rectToUse.height * 0.35
        let circlePath = UIBezierPath()
        circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: rectToUse.minY, width: size, height: size)))
        
        circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: rectToUse.midY, width: size, height: size)))
        
        circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: rectToUse.maxY, width: size, height: size)))
        
        let translationAmount = -size/2
        circlePath.applyTransform(CGAffineTransformMakeTranslation(translationAmount, translationAmount))
        circlePath.fill()
    }

}