//
//  NXFileTableCellView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXFileTableCellView: NSTableCellView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
  
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        
        let fileNameButton = self.viewWithTag(2) as? NSButton
        
        if fileNameButton == nil{
            return
        }
        
        let maxWidth = newSize.width - 100
        
        fileNameButton?.sizeToFit()
        
        if (fileNameButton?.frame.width)! > maxWidth{
            fileNameButton?.frame = NSRect(x: (fileNameButton?.frame.origin.x)!, y: (fileNameButton?.frame.origin.y)!, width: maxWidth, height: (fileNameButton?.frame.size.height)!)
        }
        
        
        
        // tracking area
        let trackingRect = fileNameButton?.bounds
        let trackingArea = NSTrackingArea(rect: trackingRect!, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        let areas = fileNameButton?.trackingAreas
        for area in areas!{
            fileNameButton?.removeTrackingArea(area)
        }
        
        fileNameButton?.addTrackingArea(trackingArea)
    }
    
    // mouse event
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

}
