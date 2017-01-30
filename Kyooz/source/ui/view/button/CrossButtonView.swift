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
    
    var showsCircle:Bool = false {
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
        
        
        let inset = (1 - scale)/2 * min(rect.height, rect.width)
        let circleRect = rect.insetBy(dx: inset, dy: inset)
        
        if showsCircle {
            let circlePath = UIBezierPath(ovalIn: circleRect)
            circlePath.fill()
        }
        
//        let crossInset = showsCircle ? 2 : inset
        let rectToUse = (showsCircle ? circleRect : rect).insetBy(dx: inset, dy: inset)
        
        let crossPath = UIBezierPath()
        crossPath.move(to: rectToUse.origin)
        crossPath.addLine(to: CGPoint(x: rectToUse.maxX, y: rectToUse.maxY))
        crossPath.move(to: CGPoint(x: rectToUse.maxX, y: rectToUse.minY))
        crossPath.addLine(to: CGPoint(x: rectToUse.minX, y: rectToUse.maxY))
        
        crossPath.lineWidth = 2.5
        crossPath.lineCapStyle = .round
        if showsCircle {
            crossPath.stroke(with: .clear, alpha: 1.0)
        } else {
            crossPath.stroke()
        }
        
    }
	
}
