//
//  NXWaitingView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/25.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXWaitingView: NSView {

    @IBOutlet weak var progressIndicatorView: NSProgressIndicator!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        
        progressIndicatorView.style = .spinning
        progressIndicatorView.controlTint = .blueControlTint
        progressIndicatorView.startAnimation(nil)
        progressIndicatorView.wantsLayer = true
        
        let layer = self.progressIndicatorView.layer
        let backLayer = layer?.sublayers?.first
        backLayer?.isHidden = true
        
        progressIndicatorView.alphaValue = 1.0
        self.alphaValue = 1.0
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
    }

    /// cannot mouse down
    override func mouseDown(with event: NSEvent) {
    }
}
