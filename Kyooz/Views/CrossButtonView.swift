//
//  CrossButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/10/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class CrossButtonView : UIButton {
	
    
    @IBInspectable
    var color:UIColor = ThemeHelper.defaultFontColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var scale:CGFloat = 0.35 {
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
    
    var showsCircle:Bool = false {
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
        
        
        let inset = (1 - scale)/2 * min(rect.height, rect.width)
        let circleRect = CGRectInset(rect, inset, inset)
        
        if showsCircle {
            let circlePath = UIBezierPath(ovalInRect: circleRect)
            circlePath.fill()
        }
        
//        let crossInset = showsCircle ? 2 : inset
        let rectToUse = CGRectInset(showsCircle ? circleRect : rect, inset, inset)
        
        let crossPath = UIBezierPath()
        crossPath.moveToPoint(rectToUse.origin)
        crossPath.addLineToPoint(CGPoint(x: rectToUse.maxX, y: rectToUse.maxY))
        crossPath.moveToPoint(CGPoint(x: rectToUse.maxX, y: rectToUse.minY))
        crossPath.addLineToPoint(CGPoint(x: rectToUse.minX, y: rectToUse.maxY))
        
        crossPath.lineWidth = 2.5
        crossPath.lineCapStyle = .Round
        if showsCircle {
            crossPath.strokeWithBlendMode(.Clear, alpha: 1.0)
        } else {
            crossPath.stroke()
        }
        
    }
	
}
