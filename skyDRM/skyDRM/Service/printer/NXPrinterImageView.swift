//
//  NXPrinterImageView.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/17/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXPrinterImageView: NSImageView {

    var watermark:NXWatermark? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let attribute = watermark?.attributeString() else {
            return
        }
        
        let rotationSize = CGSize(width: (watermark?.unitWidth)!, height:(watermark?.unitHeight)!)
        
        for x in stride(from: Int(dirtyRect.minX), to: Int(dirtyRect.maxX + (watermark?.constant.kWidthSpace)! + rotationSize.width), by: Int((watermark?.constant.kWidthSpace)! + rotationSize.width)) {
            for y in stride(from: Int(dirtyRect.minY), to: Int(dirtyRect.maxY + (watermark?.constant.kHeightSpace)! + rotationSize.height), by: Int((watermark?.constant.kHeightSpace)! + rotationSize.height)) {
                
                NSGraphicsContext.saveGraphicsState()
                let transForm = NSAffineTransform()
                transForm.translateX(by: CGFloat(x), yBy: CGFloat(y))
                transForm.rotate(byRadians: CGFloat((watermark?.radianAngle)!))
                transForm.concat()
                attribute.draw(at: NSPoint(x: CGFloat(0), y: CGFloat(0)))
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }
    
}
