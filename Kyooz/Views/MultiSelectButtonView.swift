//
//  MultiSelectButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

import UIKit

@IBDesignable
final class MultiSelectButtonView : UIButton {
    
    
    @IBInspectable
    var isActive:Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var color:UIColor = ThemeHelper.defaultFontColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var scale:CGFloat = 0.5 {
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
    
    var pathTransform:CGAffineTransform = CGAffineTransformIdentity {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    override func drawRect(rect: CGRect) {
        let colorToUse:UIColor
        if !enabled {
            colorToUse = UIColor.darkGrayColor()
        } else if highlighted {
            colorToUse = UIColor.redColor()
        } else if isActive {
            colorToUse = ThemeHelper.defaultVividColor
        } else {
            colorToUse = color
        }
        
        colorToUse.setStroke()
        colorToUse.setFill()
        
        
        
        let inset:CGFloat = (1 - scale)/2 * min(rect.height, rect.width)
        let rectToUse = CGRectInset(rect, inset, inset)
        
        let path = UIBezierPath(ovalInRect: rectToUse)
        
        path.applyTransform(pathTransform)
        if isActive {
            path.fill()
        }
        path.stroke()
        
        let checkInset =  0.2 * min(rectToUse.height, rectToUse.width)
        let checkRect = CGRectInset(rectToUse, checkInset, checkInset)
        
        let midY = checkRect.midY
        let checkPath = UIBezierPath()
        checkPath.moveToPoint(CGPoint(x: checkRect.origin.x, y: midY))
        checkPath.addLineToPoint(CGPoint(x: checkRect.origin.x + checkInset, y: midY + checkInset))
        checkPath.addLineToPoint(CGPoint(x: checkRect.maxX, y: checkRect.minY + checkInset/2))
 
        checkPath.lineWidth = 1.5
        checkPath.applyTransform(pathTransform)
        if isActive {
            checkPath.strokeWithBlendMode(.Clear, alpha: 1.0)
        } else {
            checkPath.stroke()
        }
        
        
        
        
    }
    
}