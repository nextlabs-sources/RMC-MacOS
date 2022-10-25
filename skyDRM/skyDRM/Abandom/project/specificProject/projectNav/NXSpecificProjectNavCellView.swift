//
//  NXSpecificProjectNavCellView.swift
//  skyDRM
//
//  Created by helpdesk on 3/6/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectNavCellView: NSTableCellView {
    var cellText:NSTextField?
    var cellCount:NSTextField?
    var cellImg:NSImageView?
    
    var navValue: NXSpecificProjectNavCellType?{
        didSet{
            if cellText == nil{
                cellText = self.viewWithTag(1) as? NSTextField
            }
            if cellCount == nil{
                cellCount = self.viewWithTag(2) as? NSTextField
            }
            if cellImg == nil{
                cellImg = self.viewWithTag(3) as? NSImageView
            }
            cellText?.stringValue = (navValue?.navName!)!
            if navValue?.shouldShowCount == false{
                cellCount?.isHidden = true
            }else{
                cellCount?.stringValue = (navValue?.navCount)!
                cellCount?.isHidden = false
            }
            cellImg?.image = NSImage(named:  (navValue?.navImg)!)
        }
    }
    
    // When the background changes (as a result of selection/deselection) switch appropriate colours
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            if (backgroundStyle == NSView.BackgroundStyle.dark) {
                self.cellText?.textColor = GREEN_COLOR
                self.cellCount?.textColor = WHITE_COLOR
                self.cellCount?.wantsLayer = true
                self.cellCount?.backgroundColor = GREEN_COLOR
            } else if (backgroundStyle == NSView.BackgroundStyle.light) {
                self.cellText?.textColor = BLACK_COLOR
                self.cellCount?.textColor = GREEN_COLOR
                self.cellCount?.wantsLayer = true
                self.cellCount?.backgroundColor = WHITE_COLOR
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        cellCount?.wantsLayer = true
        cellCount?.layer?.masksToBounds = true
        DispatchQueue.main.async {
            self.cellCount?.layer?.cornerRadius = (self.cellCount?.bounds.width)!/3
        }
    }

}
