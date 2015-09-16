//
//  CGUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct CGUtils {
    
    static func drawTriangleWithCurvedEdges(rect:CGRect, isPointingRight:Bool) -> UIBezierPath {
        
        let sideLength = rect.height
        let outerRadius = sideLength/pow(3, 0.5)
        let innerRadius = outerRadius/2
        let center = CGPoint(x: isPointingRight ? rect.minX + innerRadius : rect.maxX - innerRadius, y: rect.midY)
        
        let baseX = isPointingRight ? center.x - innerRadius: center.x + innerRadius
        let tipX = isPointingRight ? center.x + outerRadius: center.x - outerRadius
        
        //create the control points
        let pointA = CGPoint(x: baseX, y: center.y - sideLength/2)
        let pointB = CGPoint(x: baseX, y: center.y + sideLength/2)
        let pointC = CGPoint(x: tipX, y: center.y)
        
        let invertedFactor:CGFloat = isPointingRight ? 1 : -1
        let inset = min(rect.height * 0.03, rect.width * 0.03)
        let insetX = isPointingRight ? inset : inset * -1
        
        var path = UIBezierPath()
        path.moveToPoint(CGPoint(x: pointA.x, y: pointA.y + inset))
        path.addLineToPoint(CGPoint(x: pointB.x, y: pointB.y - inset))
        path.addQuadCurveToPoint(CGPoint(x: pointB.x + insetX, y: pointB.y), controlPoint: pointB)
        path.addLineToPoint(CGPoint(x: pointC.x - insetX, y: pointC.y + inset))
        path.addQuadCurveToPoint(CGPoint(x: pointC.x - insetX, y: pointC.y - inset), controlPoint: pointC)
        path.addLineToPoint(CGPoint(x: pointA.x + insetX, y: pointA.y))
        path.addQuadCurveToPoint(CGPoint(x: pointA.x, y: pointA.y + inset), controlPoint: pointA)
        
        return path
    }
}