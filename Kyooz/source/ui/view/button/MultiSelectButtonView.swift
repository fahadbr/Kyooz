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
    
    var pathTransform:CGAffineTransform = CGAffineTransform.identity {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    override func draw(_ rect: CGRect) {
        let colorToUse:UIColor
        if !isEnabled {
            colorToUse = UIColor.darkGray
        } else if isHighlighted {
            colorToUse = UIColor.red
        } else if isActive {
            colorToUse = ThemeHelper.defaultVividColor
        } else {
            colorToUse = color
        }
        
        colorToUse.setStroke()
        colorToUse.setFill()
        
        
        
        let inset:CGFloat = (1 - scale)/2 * min(rect.height, rect.width)
        let rectToUse = rect.insetBy(dx: inset, dy: inset)
        
        let path = UIBezierPath(ovalIn: rectToUse)
        
        path.apply(pathTransform)
        if isActive {
            path.fill()
        }
        path.stroke()
        
        let checkInset =  0.2 * min(rectToUse.height, rectToUse.width)
        let checkRect = rectToUse.insetBy(dx: checkInset, dy: checkInset)
        
        let midY = checkRect.midY
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: checkRect.origin.x, y: midY))
        checkPath.addLine(to: CGPoint(x: checkRect.origin.x + checkInset, y: midY + checkInset))
        checkPath.addLine(to: CGPoint(x: checkRect.maxX, y: checkRect.minY + checkInset/2))
 
        checkPath.lineWidth = 1.5
        checkPath.apply(pathTransform)
        if isActive {
            checkPath.stroke(with: .clear, alpha: 1.0)
        } else {
            checkPath.stroke()
        }
        
        
        
        
    }
    
}
