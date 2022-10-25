//
//  NXTrackingButton.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 07/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXTrackingButton: NSButton {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        updateTrackingArea()
    }
    
    private func updateTrackingArea() {
        if let trackingArea = self.trackingAreas.last {
            self.removeTrackingArea(trackingArea)
        }
        
        let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: ops, owner: self, userInfo: nil)
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
}
