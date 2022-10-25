//
//  NXTrayRowView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 06/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayRowViewDelegate: NSObjectProtocol {
    func HoverTableRowEnter(row: Int)
    func HoverTableRowExit(row: Int)
}

class NXTrayRowView: NSTableRowView {
    private var mouseInside: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var rowIndex = -1
    weak var rowDelegate: NXTrayRowViewDelegate?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: bounds, options: ops, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.mouseInside = true
        rowDelegate?.HoverTableRowEnter(row: rowIndex)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.mouseInside = false
        rowDelegate?.HoverTableRowExit(row: rowIndex)
    }
    
    
    class func gradientWithTargetColor(targetColor: NSColor)->NSGradient{
        let colors = [targetColor.withAlphaComponent(0), targetColor, targetColor, targetColor.withAlphaComponent(0)]
        let locations:[CGFloat] = [0.0, 0.35, 0.65, 1.0]
        return NSGradient(colors: colors, atLocations: locations, colorSpace: NSColorSpace.sRGB)!
    }
    
    
    override func drawBackground(in dirtyRect: NSRect){
        self.backgroundColor.set()
        __NSRectFill(self.bounds)
        
        if self.mouseInside{
        }
    }
    
    
    override func drawSelection(in dirtyRect: NSRect){
        if self.selectionHighlightStyle != .none {
            let blue = NSColor.init(red: 17.0/255.0, green: 108.0/255.0, blue: 214.0/255.0, alpha: 1.0)
            blue.setFill()
            blue.setStroke()
            let offsetY: CGFloat = 5
            let displayRect = NSMakeRect(dirtyRect.minX, dirtyRect.minY+offsetY, dirtyRect.width, dirtyRect.height-offsetY*2)
            let selectionPath = NSBezierPath(rect: displayRect)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
    
override  var interiorBackgroundStyle: NSView.BackgroundStyle {
        return .light
    }
    
}
