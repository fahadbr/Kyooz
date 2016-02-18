//
//  ApplicationIconView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/20/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@IBDesignable
class ApplicationIconView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ThemeHelper.defaultTableCellColor
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var scaleFactor:CGFloat = 0.55
    var offsetFactor:CGFloat = 0.25
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
//    override func drawRect(rect: CGRect) {
//        backgroundColor = ThemeHelper.defaultTableCellColor
//        
//        let smallerSide = min(rect.width, rect.height)
//        let triangleSideLength:CGFloat = smallerSide * scaleFactor
//        let triangleHeight:CGFloat = pow(3, 0.5)/2 * triangleSideLength
//        let offsetAmount = triangleHeight * offsetFactor
//        let tallRectWidth = triangleSideLength/4
//        
//        let triangleRect = CGRect(x: rect.midX - offsetAmount, y: rect.midY - triangleSideLength/2, width: triangleSideLength, height: triangleSideLength)
//        let tallRect = CGRect(x: rect.midX - offsetAmount - tallRectWidth * 1.3, y: rect.midY - triangleSideLength/2, width: tallRectWidth, height: triangleSideLength)
//        
//        let path = UIBezierPath()
//        path.appendPath(CGUtils.drawTriangleWithCurvedEdges(triangleRect, isPointingRight: true))
//        path.appendPath(CGUtils.drawRectWithCurvedEdges(tallRect))
//        
//        ThemeHelper.defaultVividColor.setFill()
//        
//        path.fill()
//        
//    }


}
