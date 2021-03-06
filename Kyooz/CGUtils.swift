//
//  CGUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct CGUtils {
    
    static func drawTriangleWithCurvedEdges(_ rect:CGRect, isPointingRight:Bool) -> UIBezierPath {
        
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
        
        let inset = min(rect.height * 0.03, rect.width * 0.03)
        let insetX = isPointingRight ? inset : inset * -1
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: pointA.x, y: pointA.y + inset))
        path.addLine(to: CGPoint(x: pointB.x, y: pointB.y - inset))
        path.addQuadCurve(to: CGPoint(x: pointB.x + insetX, y: pointB.y), controlPoint: pointB)
        path.addLine(to: CGPoint(x: pointC.x - insetX, y: pointC.y + inset))
        path.addQuadCurve(to: CGPoint(x: pointC.x - insetX, y: pointC.y - inset), controlPoint: pointC)
        path.addLine(to: CGPoint(x: pointA.x + insetX, y: pointA.y))
        path.addQuadCurve(to: CGPoint(x: pointA.x, y: pointA.y + inset), controlPoint: pointA)
        
        return path
    }
    
    static func drawRectWithCurvedEdges(_ rect:CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let origin = rect.origin
        let point2 = CGPoint(x:rect.maxX, y:rect.minY)
        let point3 = CGPoint(x:rect.maxX, y:rect.maxY)
        let point4 = CGPoint(x:rect.minX, y:rect.maxY)
        
        let inset = min(rect.width * 0.15, rect.height * 0.15)
        
        path.move(to: CGPoint(x: origin.x + inset, y: origin.y))
        
        path.addLine(to: CGPoint(x: point2.x - inset, y: point2.y))
        path.addQuadCurve(to: CGPoint(x: point2.x, y: point2.y + inset), controlPoint: point2)
        path.addLine(to: CGPoint(x: point3.x, y: point3.y - inset))
        path.addQuadCurve(to: CGPoint(x: point3.x - inset , y: point3.y), controlPoint: point3)
        path.addLine(to: CGPoint(x: point4.x + inset, y: point4.y))
        path.addQuadCurve(to: CGPoint(x: point4.x, y: point4.y - inset), controlPoint: point4)
        path.addLine(to: CGPoint(x: origin.x, y: origin.y + inset))
        path.addQuadCurve(to: CGPoint(x: origin.x + inset, y: origin.y), controlPoint: origin)
        
        return path
    }
}
