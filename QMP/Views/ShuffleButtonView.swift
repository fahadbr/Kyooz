//
//  ShuffleButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/24/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

@IBDesignable
final class ShuffleButtonView : UIButton {
    
    
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
    
    override var highlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
 
    override func drawRect(rect: CGRect) {
        if highlighted {
            ThemeHelper.defaultTintColor.setFill()
            ThemeHelper.defaultTintColor.setStroke()
        } else if isActive {
            ThemeHelper.defaultVividColor.setFill()
            ThemeHelper.defaultVividColor.setStroke()
        } else {
            color.setFill()
            color.setStroke()
        }
        
        
        let path = UIBezierPath()
        let xInset = rect.width * 0.30
        let yInset = rect.height * 0.35
        
        let insetRect = CGRectInset(rect, xInset, yInset)
        drawCurve(path, rect: insetRect, invertY: false)
        drawCurve(path, rect: insetRect, invertY: true)
        
        path.lineWidth = min(insetRect.height, insetRect.width) * 0.15
        path.lineCapStyle = CGLineCap.Round
        path.stroke()
        
        let smallerSide = min(insetRect.width, insetRect.height)
        let triangleRectSize = CGSize(width: smallerSide * 0.35, height: smallerSide * 0.35)
        
        let triangleRect1 = CGRect(origin: CGPoint(x: insetRect.maxX - triangleRectSize.width/2, y: insetRect.minY - triangleRectSize.height/2), size: triangleRectSize)
        let trianglePath1 = CGUtils.drawTriangleWithCurvedEdges(triangleRect1, isPointingRight: true)
        
        trianglePath1.stroke()
        trianglePath1.fill()
        
        let triangleRect2 = CGRect(origin: CGPoint(x: insetRect.maxX - triangleRectSize.width/2, y: insetRect.maxY - triangleRectSize.height/2), size: triangleRectSize)
        let trianglePath2 = CGUtils.drawTriangleWithCurvedEdges(triangleRect2, isPointingRight: true)
        
        trianglePath2.stroke()
        trianglePath2.fill()
    }
    
    private func drawCurve(path:UIBezierPath, rect:CGRect, invertY:Bool) {
        let minY:CGFloat
        let maxY:CGFloat
        if invertY {
            minY = rect.maxY
            maxY = rect.origin.y
        } else {
            minY = rect.origin.y
            maxY = rect.maxY
        }
        
        let midX = rect.midX
        
        path.moveToPoint(CGPoint(x:rect.origin.x, y: minY))
        path.addCurveToPoint(CGPoint(x: rect.maxX, y: maxY), controlPoint1: CGPoint(x: midX, y: minY), controlPoint2: CGPoint(x: midX, y: maxY))
    }
    
}