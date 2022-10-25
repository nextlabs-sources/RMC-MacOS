//
//  NXGraphic.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/27.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class NXGraphic: NSObject {
    class func drawRoundedRect(rect: CGRect, inContext context: CGContext?,
                                 radius: CGFloat, borderColor: CGColor?, fillColor: CGColor) {
        // 1
        let path = CGMutablePath()
        
        // 2
        path.move( to: CGPoint(x:  rect.midX, y:rect.minY ))
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.closeSubpath()
        
        // 3
        if borderColor != nil {
            context?.setLineWidth(1.0)
            context?.setStrokeColor(borderColor!)
        }
        context?.setFillColor(fillColor)
        
        // 4
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
    }

}
