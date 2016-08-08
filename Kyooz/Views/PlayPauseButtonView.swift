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
	
	@IBInspectable
	var scale:CGFloat = 1
    
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
    
    override var isEnabled:Bool {
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
        
        let path = isPlayButton ? drawPlayButton(rect) : drawPauseButton(rect)
        
        
        path.fill()
        

        
        if hasOuterFrame {
            let outerRect = rect.insetBy(dx: rect.width * 0.01, dy: rect.height * 0.01)
            let outerRectPath = CGUtils.drawRectWithCurvedEdges(outerRect)
            outerRectPath.stroke()
        }
    }
    
    private func drawPlayButton(_ rect:CGRect) -> UIBezierPath {
        //the scale factor used to determine the triangles size relative to the encapsuling views frame

        
        let scaleFactor:CGFloat = 0.5 * scale
        let inverseScaleFactor:CGFloat = 1 - scaleFactor
        
        //tX and tY is the amount to translate the path
        let tX:CGFloat = rect.width *  inverseScaleFactor * 0.5
        let tY:CGFloat = rect.height * inverseScaleFactor * 0.5
        
        let triangleRect = rect.insetBy(dx: tX, dy: tY)
        let path = CGUtils.drawTriangleWithCurvedEdges(triangleRect, isPointingRight: true)
        
        path.apply(CGAffineTransform(translationX: (triangleRect.midX - path.bounds.midX), y: 0))
        
        return path
    }
    
    
    private func drawPauseButton(_ rect:CGRect) -> UIBezierPath {
        let pauseButtonRectWidth:CGFloat = rect.width * 0.20 * scale
        let pauseButtonRectHeight:CGFloat = rect.height * 0.50 * scale
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
        firstRectPath.append(CGUtils.drawRectWithCurvedEdges(secondRect))
        
        return firstRectPath
    }

}
