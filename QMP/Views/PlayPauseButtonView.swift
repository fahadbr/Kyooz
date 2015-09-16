//
//  PauseButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/29/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
class PlayPauseButtonView: UIButton {

    @IBInspectable
    var isPlayButton:Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var hasOuterFrame:Bool = true
    
    override var highlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        let path = isPlayButton ? drawPlayButton(rect) : drawPauseButton(rect)
        
        
        if highlighted {
            UIColor.lightGrayColor().setFill()
            UIColor.lightGrayColor().setStroke()
        } else {
            UIColor.whiteColor().setFill()
            UIColor.whiteColor().setStroke()
        }
        
        path.fill()
        

        
        if hasOuterFrame {
            let outerRect = CGRectInset(rect, rect.width * 0.01, rect.height * 0.01)
            let outerRectPath = drawRectWithCurvedEdges(outerRect)
            outerRectPath.stroke()
        }
    }
    
    private func drawPlayButton(rect:CGRect) -> UIBezierPath {
        //the scale factor used to determine the triangles size relative to the encapsuling views frame

        
        let scaleFactor:CGFloat = 0.5
        let inverseScaleFactor:CGFloat = 1 - scaleFactor
        
        //tX and tY is the amount to translate the path
        let tX:CGFloat = rect.width *  inverseScaleFactor * 0.5
        let tY:CGFloat = rect.height * inverseScaleFactor * 0.5
        
        let triangleRect = CGRectInset(rect, tX, tY)
        let path = CGUtils.drawTriangleWithCurvedEdges(triangleRect, isPointingRight: true)
        
        path.applyTransform(CGAffineTransformMakeTranslation((triangleRect.midX - path.bounds.midX), 0))
        
        return path
    }
    
    
    private func drawPauseButton(rect:CGRect) -> UIBezierPath {
        let pauseButtonRectWidth:CGFloat = rect.width * 0.20
        let pauseButtonRectHeight:CGFloat = rect.height * 0.50
        let pauseButtonRectSize = CGSize(width: pauseButtonRectWidth, height: pauseButtonRectHeight)
        let gap:CGFloat = pauseButtonRectWidth * 0.4
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        let firstRectOrigin = CGPoint(
            x: center.x - gap/2 - pauseButtonRectWidth,
            y: center.y - pauseButtonRectHeight/2)
        let firstRect = CGRect(origin: firstRectOrigin, size: pauseButtonRectSize)
        
        let firstRectPath = drawRectWithCurvedEdges(firstRect)
        
        let secondRectOrigin = CGPoint(
            x: center.x + gap/2,
            y: center.y - pauseButtonRectHeight/2)
        let secondRect = CGRect(origin: secondRectOrigin, size: pauseButtonRectSize)
        firstRectPath.appendPath(drawRectWithCurvedEdges(secondRect))
        
        return firstRectPath
    }
    
    private func drawRectWithCurvedEdges(rect:CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let origin = rect.origin
        let point2 = CGPoint(x:rect.maxX, y:rect.minY)
        let point3 = CGPoint(x:rect.maxX, y:rect.maxY)
        let point4 = CGPoint(x:rect.minX, y:rect.maxY)
        
        let inset = min(rect.width * 0.15, rect.height * 0.15)
        
        path.moveToPoint(CGPoint(x: origin.x + inset, y: origin.y))

        path.addLineToPoint(CGPoint(x: point2.x - inset, y: point2.y))
        path.addQuadCurveToPoint(CGPoint(x: point2.x, y: point2.y + inset), controlPoint: point2)
        path.addLineToPoint(CGPoint(x: point3.x, y: point3.y - inset))
        path.addQuadCurveToPoint(CGPoint(x: point3.x - inset , y: point3.y), controlPoint: point3)
        path.addLineToPoint(CGPoint(x: point4.x + inset, y: point4.y))
        path.addQuadCurveToPoint(CGPoint(x: point4.x, y: point4.y - inset), controlPoint: point4)
        path.addLineToPoint(CGPoint(x: origin.x, y: origin.y + inset))
        path.addQuadCurveToPoint(CGPoint(x: origin.x + inset, y: origin.y), controlPoint: origin)
        
        return path
    }
    
    

    

}
