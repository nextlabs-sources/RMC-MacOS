//
//  NXStorageIndicatorView.swift
//  skyDRM
//
//  Created by nextlabs on 10/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXStorageIndicatorView: NSView {
    
    private let borderColor = NSColor(red: 212/255, green: 212/255, blue: 223/255, alpha: 1.0)
    private let driveColor = NSColor(red: 52/255, green: 153/255, blue: 76/255, alpha: 1.0)
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawProgressInternal()
        // Drawing code here.
    }
    private var used: CGFloat = 0
    private var total: CGFloat = 0
    
    private let indicatorheight: CGFloat = 10
    
    func drawProgress(used: CGFloat, total: CGFloat) {
        self.used = used
        self.total = total
        draw(frame)
    }
    private func drawProgressInternal(){
        
        // draw whole
        let totalRect = CGRect(x: 0, y: frame.height - indicatorheight, width: frame.width, height: indicatorheight)
        let context = NSGraphicsContext.current?.cgContext
        drawRoundedRect(rect: totalRect, inContext: context,
                        radius: totalRect.height / 2,
                        borderColor: borderColor.cgColor,
                        fillColor: NSColor.white.cgColor)
        guard total != 0,
            used <= total else {
                return
        }
        //draw mydrive
        let driveWidth = used * frame.width / total
        let drvieClipRect = CGRect(x: 0, y: 0, width: driveWidth, height: indicatorheight)
        context?.saveGState()
        context?.clip(to: drvieClipRect)
        drawRoundedRect(rect: totalRect, inContext: context, radius: totalRect.height / 2, borderColor: nil, fillColor: driveColor.cgColor)
        context?.restoreGState()
    
        
    }
    
    private func drawRoundedRect(rect: CGRect, inContext context: CGContext?,
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
