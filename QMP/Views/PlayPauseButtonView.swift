//
//  PauseButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/29/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
final class PlayPauseButtonView: UIButton {

    @IBInspectable
    var isPlayButton:Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var hasOuterFrame:Bool = true
    
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
    
    override var enabled:Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        if !enabled {
            UIColor.darkGrayColor().setFill()
            UIColor.darkGrayColor().setStroke()
        } else if highlighted {
            if let highlightColor = titleColorForState(.Highlighted) {
                highlightColor.setFill()
                highlightColor.setStroke()
            } else {
                UIColor.darkGrayColor().setFill()
                UIColor.darkGrayColor().setStroke()
            }
        } else {
            color.setFill()
            color.setStroke()
        }
        
        let path = isPlayButton ? drawPlayButton(rect) : drawPauseButton(rect)
        
        
        path.fill()
        

        
        if hasOuterFrame {
            let outerRect = CGRectInset(rect, rect.width * 0.01, rect.height * 0.01)
            let outerRectPath = CGUtils.drawRectWithCurvedEdges(outerRect)
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
        
        let firstRectPath = CGUtils.drawRectWithCurvedEdges(firstRect)
        
        let secondRectOrigin = CGPoint(
            x: center.x + gap/2,
            y: center.y - pauseButtonRectHeight/2)
        let secondRect = CGRect(origin: secondRectOrigin, size: pauseButtonRectSize)
        firstRectPath.appendPath(CGUtils.drawRectWithCurvedEdges(secondRect))
        
        return firstRectPath
    }

}
