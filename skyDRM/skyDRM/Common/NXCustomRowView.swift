//
//  NXCustomRowView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/1/10.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXCustomRowView: NSTableRowView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 1, 1)
            NSColor(calibratedWhite: 0.9, alpha: 1).setStroke()
            let color = NSColor(colorWithHex: "#DCDCDC") //NSColor.color(withHexColor: "#DCDCDC")
            color!.setFill()
            let selectionPath = NSBezierPath(rect: selectionRect)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
}
