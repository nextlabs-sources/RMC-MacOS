//
//  NXSeparatorView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/6.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXSeparatorView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        self.layer?.backgroundColor = NSColor.black.cgColor
    }
    
}
