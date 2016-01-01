//
//  SkipTrackButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class SkipTrackButtonView: UIButton {

    override var highlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var isForwardButton:Bool = false
    
    @IBInspectable
    var scale:CGFloat = 1 {
        didSet {
            scaleFactor = 0.5 * scale
        }
    }
    
    var scaleFactor:CGFloat = 0.5
    var offsetFactor:CGFloat = 0.8
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        
        let smallerSide = min(rect.width, rect.height)
        let sideLength:CGFloat = smallerSide * scaleFactor
        let triangleHeight:CGFloat = pow(3, 0.5)/2 * sideLength
        let offsetAmount = triangleHeight * offsetFactor
        
        let leftRectOriginX = rect.midX - offsetAmount
        let rightRectOriginX = rect.midX - triangleHeight + offsetAmount
        
        let rightRect = CGRect(x: rightRectOriginX, y: rect.midY - sideLength/2, width: sideLength, height: sideLength)
        let leftRect = CGRect(x: leftRectOriginX, y: rect.midY - sideLength/2, width: sideLength, height: sideLength)
        
        
        let path = UIBezierPath()
        path.appendPath(CGUtils.drawTriangleWithCurvedEdges(rightRect, isPointingRight: isForwardButton))
        path.appendPath(CGUtils.drawTriangleWithCurvedEdges(leftRect, isPointingRight: isForwardButton))
        
        let centerOffset = rect.midX - path.bounds.midX
        path.applyTransform(CGAffineTransformMakeTranslation(centerOffset, 0))
        
        let strokePath = UIBezierPath()
        strokePath.lineCapStyle = CGLineCap.Round
        strokePath.lineWidth = sideLength * 0.10
        let strokeEndX = isForwardButton ? path.bounds.maxX : path.bounds.minX
        strokePath.moveToPoint(CGPoint(x: strokeEndX, y: path.bounds.minY))
        strokePath.addLineToPoint(CGPoint(x: strokeEndX, y: path.bounds.maxY))
        
        
        if highlighted {
            UIColor.lightGrayColor().setFill()
            UIColor.lightGrayColor().setStroke()
        } else {
            UIColor.whiteColor().setFill()
            UIColor.whiteColor().setStroke()
        }
            
        strokePath.stroke()
        path.fill()
    }
    
}
