//
//  NXMouseEventImageView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/4.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXMouseEventImageViewDelegate: NSObjectProtocol {
    func mouseDownImageView(sender: Any, event: NSEvent)
}

class NXMouseEventImageView: NSImageView {

    weak var mouseDelegate: NXMouseEventImageViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: bounds, options: ops, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        mouseDelegate?.mouseDownImageView(sender: self, event: event)
    }
}
