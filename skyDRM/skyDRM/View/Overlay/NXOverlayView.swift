//
//  NXOverlayView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXOverlayView: NSView {
    
    var watermark:NXWatermark? = nil
    
    init(watermark:NXWatermark) {
        super.init(frame: NSRect.zero)
        self.watermark = watermark
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
