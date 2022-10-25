//
//  NXDriveIndicatorView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/27.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXDriveIndicatorViewDelegate: NSObjectProtocol {
    func onView(sender: Any)
}

class NXDriveIndicatorView: NSView {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var sizeLabel: NSTextField!
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var viewBtn: NXMouseEventButton!
    
    weak var delegate: NXDriveIndicatorViewDelegate?
    
    var color = NSColor.white {
        willSet {
            needsDisplay = true
        }
    }
    var name = "" {
        willSet {
            DispatchQueue.main.async {
                self.nameLabel.stringValue = newValue
            }
        }
    }
    var size = "" {
        willSet {
            DispatchQueue.main.async {
                self.sizeLabel.stringValue = newValue
                self.sizeLabel.sizeToFit()
            }
        }
    }
    var driveImage = NSImage(named:  "mydrive") {
        willSet {
            DispatchQueue.main.async {
                self.image.image = newValue
            }
        }
    }
    var view = "" {
        willSet {
            DispatchQueue.main.async {
                self.viewBtn.title = newValue
                self.viewBtn.sizeToFit()
            }
        }
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            wantsLayer = true
            layer?.borderColor = NSColor.black.cgColor
            layer?.borderWidth = 0.3
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let frame = NSMakeRect(15, 85, 10, 10)
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        context?.clip(to: frame)
        NXGraphic.drawRoundedRect(rect: frame, inContext: context, radius: frame.height/3, borderColor: color.cgColor, fillColor: color.cgColor)
        context?.restoreGState()
        // Drawing code here.
    }
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    @IBAction func onView(_ sender: Any) {
        delegate?.onView(sender: self)
    }
}
