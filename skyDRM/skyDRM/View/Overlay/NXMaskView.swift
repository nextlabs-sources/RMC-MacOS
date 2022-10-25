//
//  NXMaskView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/1/9.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXMaskView: NSView {
    
    var showView: NSView? = nil
    
    init(showView: NSView) {
        super.init(frame: NSRect.zero)
        self.showView = showView
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.blue.cgColor
        self.alphaValue = 0.4
    
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    
        // Drawing code here.
    }
    
}
