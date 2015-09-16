//
//  SkipTrackButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
class SkipTrackButtonView: UIButton {

    override var highlighted:Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var isForwardButton:Bool = false
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        
        let scaleFactor:CGFloat = 0.5
        let smallerSide = min(rect.width, rect.height)
        let sideLength:CGFloat = smallerSide * scaleFactor
        let triangleHeight:CGFloat = pow(3, 0.5)/2 * sideLength
        
        let leftRect = CGRect(x: rect.midX - triangleHeight, y: rect.midY - sideLength/2, width: sideLength, height: sideLength)
        let rightRect = CGRect(x: rect.midX, y: rect.midY - sideLength/2, width: sideLength, height: sideLength)
        
        
        let path = UIBezierPath()
        path.appendPath(CGUtils.drawTriangleWithCurvedEdges(leftRect, isPointingRight: isForwardButton))
        path.appendPath(CGUtils.drawTriangleWithCurvedEdges(rightRect, isPointingRight: isForwardButton))
        
        let strokePath = UIBezierPath()
        strokePath.lineCapStyle = kCGLineCapRound
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
