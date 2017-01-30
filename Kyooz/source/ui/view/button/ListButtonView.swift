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
        
        var rectToUse = rect
        if alignRight {
            rectToUse.size.width = rectToUse.size.height
            rectToUse.origin.x = rect.maxX - rectToUse.size.width
        }
        let xScale = (1 - scale)/2
        let insetX = rectToUse.width * xScale
        let insetY = rectToUse.height * (xScale * 1.2)
        let insetRect = rectToUse.insetBy(dx: insetX, dy: insetY)
        
        let minX = insetRect.origin.x
        let maxX = insetRect.maxX
        
        let path = UIBezierPath()
        let minY = insetRect.origin.y
        path.move(to: insetRect.origin)
        path.addLine(to: CGPoint(x: maxX, y: minY))
        
        let midY = insetRect.midY
        path.move(to: CGPoint(x: minX, y: midY))
        path.addLine(to: CGPoint(x: maxX, y: midY))
        
        let maxY = insetRect.maxY
        path.move(to: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.lineWidth = insetRect.height * 0.15
        
        if showBullets {
            path.apply(CGAffineTransform(translationX: insetRect.width * 0.15, y: 0))
            let size = insetRect.height * 0.3
            let circlePath = UIBezierPath()
            circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: minY, width: size, height: size)))
            
            circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: midY, width: size, height: size)))
            
            circlePath.append(UIBezierPath(ovalIn: CGRect(x: minX, y: maxY, width: size, height: size)))
            
            let translationAmount = -size/2
            circlePath.apply(CGAffineTransform(translationX: translationAmount, y: translationAmount))
            if let t = pathTransform {
                circlePath.apply(t)
            }
            circlePath.fill()
        }
        
        if let t = pathTransform {
            path.apply(t)
        }
        
        path.stroke()
        
  
    }

}
