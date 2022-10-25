//
//  NXToastView.swift
//  skyDRM
//
//  Created by xx-huang on 01/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXToastView : NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        __NSRectFill(bounds)
        
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10.0, yRadius: 10.0)
        NSColor(calibratedWhite: 0.0, alpha: 0.5).set()
        path.fill()
    }
}

final class NXToastWindow : NSWindow {
    
    let queue = DispatchQueue(label: "com.nxrmc.skyDRM.NXToastWindow.timer")
    var timer: DispatchSourceTimer?
    @IBOutlet weak var label: NSTextField!
    
    static let sharedInstance = NXCommonUtils.createToastView(xibName: "NXToastView", identifier: "Toast")
    
    fileprivate var isCancel = false
    
    func toast(_ str: String) {
        if timer == nil {
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: DispatchTime.now()+2.0)
            timer?.setEventHandler {
                self.fadeOut()
            }
            timer?.resume()
        }
        label.stringValue = str
        alphaValue = 1.0
        
        orderFront(nil)
    }
    override func awakeFromNib() {
        hasShadow = true
        isOpaque = false
        _ = NSWindow.Level.init(100)
        isMovable = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = true
    }
    
    func fadeOut() {
        animator().alphaValue = 0.0
        self.orderOut(nil)
        timer?.cancel()
        timer = nil
    }
}
