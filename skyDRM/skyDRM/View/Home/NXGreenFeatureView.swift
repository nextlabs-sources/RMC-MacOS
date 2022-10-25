//
//  NXGreenFeatureView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/28.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXGreenFeatureViewDelegate: NSObjectProtocol {
    func mouseDownView(sender: Any, event: NSEvent)
}

class NXGreenFeatureView: NSView {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    weak var mouseDelegate: NXGreenFeatureViewDelegate?
    
    private let crossWidth:CGFloat = 20
    private let crossHeight:CGFloat = 8
    var name = "" {
        willSet {
            DispatchQueue.main.async {
                self.nameLabel.stringValue = newValue
            }
        }
    }
    var isCross = false {
        willSet {
            if newValue == true {
                needsDisplay = true
            }
        }
    }
    var image: NSImage? {
        willSet {
            if let _ = newValue {
                DispatchQueue.main.async {
                    self.imageView.image = newValue
                }
            }
        }
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            wantsLayer = true
            layer?.cornerRadius = frame.height/20
            nameLabel.textColor = NSColor.white
            nameLabel.font = NSFont(name: "Arial", size: 16)
            
            let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
            let trackingArea = NSTrackingArea(rect: bounds, options: ops, owner: self, userInfo: nil)
            self.addTrackingArea(trackingArea)
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let startColor = NSColor(colorWithHex: "#6FB75A", alpha: 1.0)
        let endColor = NSColor(colorWithHex: "#99CE66", alpha: 1.0)
        let gradient = NSGradient(starting: startColor!, ending: endColor!)
        gradient?.draw(in: bounds, angle: -30)
        
        if isCross == true {
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            let path = CGMutablePath()
            var startPt = CGPoint(x: (frame.width - crossWidth)/2, y: imageView.frame.maxX - imageView.frame.width/2)
            var endPt = CGPoint(x: (frame.width + crossWidth)/2, y: imageView.frame.maxX - imageView.frame.width/2)
            path.move(to: startPt)
            path.addLine(to: endPt)
            startPt = CGPoint(x: frame.width/2, y: imageView.frame.maxX - imageView.frame.width/2 - crossWidth/2)
            endPt = CGPoint(x: frame.width/2, y: imageView.frame.maxX - imageView.frame.width/2 + crossWidth/2)
            path.move(to: startPt)
            path.addLine(to: endPt)
            context?.addPath(path)
            context?.setStrokeColor(NSColor.white.cgColor)
            context?.setLineWidth(crossHeight/2)
            context?.strokePath()
            context?.restoreGState()
        }
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
        mouseDelegate?.mouseDownView(sender: self, event: event)
    }
}
