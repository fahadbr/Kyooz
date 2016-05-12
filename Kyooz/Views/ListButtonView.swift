//
//  ListButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/5/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class ListButtonView: UIButton {

    @IBInspectable
    var alignRight:Bool = false
    
    @IBInspectable
    var scale:CGFloat = 0.4 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var color:UIColor = ThemeHelper.defaultFontColor
    
    @IBInspectable
    var showBullets:Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var pathTransform:CGAffineTransform? {
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
        let colorToUse:UIColor
        if !enabled {
            colorToUse = UIColor.darkGrayColor()
        } else if highlighted {
            colorToUse = ThemeHelper.defaultVividColor
        } else {
            colorToUse = color
        }
        
        colorToUse.setStroke()
        colorToUse.setFill()
        
        var rectToUse = rect
        if alignRight {
            rectToUse.size.width = rectToUse.size.height
            rectToUse.origin.x = rect.maxX - rectToUse.size.width
        }
        let xScale = (1 - scale)/2
        let insetX = rectToUse.width * xScale
        let insetY = rectToUse.height * (xScale * 1.2)
        let insetRect = CGRectInset(rectToUse, insetX, insetY)
        
        let minX = insetRect.origin.x
        let maxX = insetRect.maxX
        
        let path = UIBezierPath()
        let minY = insetRect.origin.y
        path.moveToPoint(insetRect.origin)
        path.addLineToPoint(CGPoint(x: maxX, y: minY))
        
        let midY = insetRect.midY
        path.moveToPoint(CGPoint(x: minX, y: midY))
        path.addLineToPoint(CGPoint(x: maxX, y: midY))
        
        let maxY = insetRect.maxY
        path.moveToPoint(CGPoint(x: minX, y: maxY))
        path.addLineToPoint(CGPoint(x: maxX, y: maxY))
        path.lineWidth = insetRect.height * 0.15
        
        if showBullets {
            path.applyTransform(CGAffineTransformMakeTranslation(insetRect.width * 0.15, 0))
            let size = insetRect.height * 0.3
            let circlePath = UIBezierPath()
            circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: minY, width: size, height: size)))
            
            circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: midY, width: size, height: size)))
            
            circlePath.appendPath(UIBezierPath(ovalInRect: CGRect(x: minX, y: maxY, width: size, height: size)))
            
            let translationAmount = -size/2
            circlePath.applyTransform(CGAffineTransformMakeTranslation(translationAmount, translationAmount))
            if let t = pathTransform {
                circlePath.applyTransform(t)
            }
            circlePath.fill()
        }
        
        if let t = pathTransform {
            path.applyTransform(t)
        }
        
        path.stroke()
        
  
    }

}
