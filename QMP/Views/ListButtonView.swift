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
                color = UIColor.darkGrayColor()
            }
        } else {
            color = self.color
        }
        color.setStroke()
        
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
        path.moveToPoint(insetRect.origin)
        path.addLineToPoint(CGPoint(x: maxX, y: insetRect.origin.y))
        
        let midY = insetRect.midY
        path.moveToPoint(CGPoint(x: minX, y: midY))
        path.addLineToPoint(CGPoint(x: maxX, y: midY))
        
        let maxY = insetRect.maxY
        path.moveToPoint(CGPoint(x: minX, y: maxY))
        path.addLineToPoint(CGPoint(x: maxX, y: maxY))
        path.lineWidth = 2
        path.stroke()
    }

}
