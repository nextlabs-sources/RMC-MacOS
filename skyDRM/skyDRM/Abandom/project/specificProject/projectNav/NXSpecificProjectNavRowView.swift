//
//  NXSpecificProjectNavRowView.swift
//  skyDRM
//
//  Created by helpdesk on 2/22/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectNavRowView: NSTableRowView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if isSelected {
            WHITE_COLOR.set()
            
            NSColor(calibratedWhite: 0.72, alpha: 1.0).setStroke()
            NSColor(calibratedWhite: 0.82, alpha: 1.0).setFill()
            
            __NSRectFill(dirtyRect)
            layer?.cornerRadius = 2
        }
    }
    
}
