//
//  NXMouseEventButton.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/5.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa
protocol NXMouseEventButtonDelegate: NSObjectProtocol {
}

class NXMouseEventButton: NSButton {
    weak var mouseDelegate: NXMouseEventButtonDelegate?
    override var title: String {
        willSet{
            DispatchQueue.main.async {
                let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
                let oldTrackingArea = NSTrackingArea(rect: self.bounds, options: ops, owner: self, userInfo: nil)
                self.removeTrackingArea(oldTrackingArea)
                
                if let textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0) {
                    let pstyle = NSMutableParagraphStyle()
                    pstyle.alignment = .center
                    let titleAttr = NSMutableAttributedString(attributedString: self.attributedTitle)
                    titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, newValue.count))
                    self.attributedTitle = titleAttr
                }
            }
        }
        didSet {
            DispatchQueue.main.async {
                self.sizeToFit()
                let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
                let trackingArea = NSTrackingArea(rect: self.bounds, options: ops, owner: self, userInfo: nil)
                self.addTrackingArea(trackingArea)
            }
        }
    }
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
}
