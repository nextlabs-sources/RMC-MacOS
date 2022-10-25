//
//  NXMouseEventStackView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
protocol NXMouseEventStackViewDelegate: NSObjectProtocol {
    func mouseDownStackView(sender: Any, event: NSEvent)
}
class NXMouseEventStackView: NSStackView {
    
    weak var mouseDelegate: NXMouseEventStackViewDelegate?
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
        mouseDelegate?.mouseDownStackView(sender: self, event: event)
    }

}
