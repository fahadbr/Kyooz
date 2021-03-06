//
//  RepeatButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/24/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class RepeatButtonView: UIButton {

    var repeatState:RepeatState = .off
    
    var color:UIColor = ThemeHelper.defaultFontColor {
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
            colorToUse = UIColor.red
        } else if repeatState != .off {
            colorToUse = ThemeHelper.defaultVividColor
        } else {
            colorToUse = color
        }
        
        colorToUse.setStroke()
        colorToUse.setFill()
        
        
        let insetX = rect.width * 0.30
        let insetY = rect.height * 0.35
        let insetRect = rect.insetBy(dx: insetX, dy: insetY)
        
        let path = UIBezierPath()
        
        drawCurve(path, insetRect: insetRect, inverted: false)
        drawCurve(path, insetRect: insetRect, inverted: true)
        
        path.lineWidth = min(insetRect.height, insetRect.width) * 0.15
        path.lineCapStyle = CGLineCap.round
        path.stroke()
        
        let smallerSide = min(insetRect.width, insetRect.height)
        let triangleRectSize = CGSize(width: smallerSide * 0.35, height: smallerSide * 0.35)
        
        let triangleRect1 = CGRect(origin: CGPoint(x: insetRect.maxX - triangleRectSize.width/2, y: insetRect.minY - triangleRectSize.height/2), size: triangleRectSize)
        let trianglePath1 = CGUtils.drawTriangleWithCurvedEdges(triangleRect1, isPointingRight: true)
        trianglePath1.stroke()
        trianglePath1.fill()
        
        let triangleRect2 = CGRect(origin: CGPoint(x: insetRect.minX - triangleRectSize.width/2, y: insetRect.maxY - triangleRectSize.height/2), size: triangleRectSize)
        let trianglePath2 = CGUtils.drawTriangleWithCurvedEdges(triangleRect2, isPointingRight: false)
        trianglePath2.stroke()
        trianglePath2.fill()
        
        if repeatState == .one {
            drawRepeatOne(insetRect)
        }
        
    }
    
    private func drawCurve(_ path:UIBezierPath, insetRect:CGRect, inverted:Bool) {
        let xStartingPoint:CGFloat
        let xEndingPoint:CGFloat
        let midY = insetRect.midY
        let yEdge:CGFloat
        if inverted {
            xStartingPoint = insetRect.maxX
            xEndingPoint = insetRect.origin.x
            yEdge = insetRect.maxY
        } else {
            xStartingPoint = insetRect.origin.x
            xEndingPoint = insetRect.maxX
            yEdge = insetRect.origin.y
        }
        
        path.move(to: CGPoint(x: xStartingPoint, y: midY))
        
        path.addQuadCurve(to: CGPoint(x: insetRect.midX, y: yEdge), controlPoint: CGPoint(x: xStartingPoint, y: yEdge))
        path.addLine(to: CGPoint(x: xEndingPoint, y: yEdge))
    }
    
    private func drawRepeatOne(_ insetRect:CGRect) {
        let xInset = insetRect.width * 0.05
        let yInset = insetRect.height * 0.30
        let midX = insetRect.midX
        let maxY = insetRect.maxY - yInset
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: midX - xInset, y: insetRect.minY + yInset * 1.2))
        path.addLine(to: CGPoint(x: midX, y: insetRect.minY + yInset))
        path.addLine(to: CGPoint(x: midX, y: maxY))
        path.move(to: CGPoint(x: midX - xInset, y: maxY))
        path.addLine(to: CGPoint(x: midX + xInset, y: maxY))
        path.lineWidth = min(insetRect.width, insetRect.height) * 0.10
        path.lineCapStyle = CGLineCap.round
        path.stroke()
    }


}
