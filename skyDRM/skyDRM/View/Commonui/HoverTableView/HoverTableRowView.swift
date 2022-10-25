//
//  HoverTableRowView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class HoverTableRowView: NSTableRowView {
    var mouseInside: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    var rowIndex = -1
    weak var rowDelegate: HoverTableRowDelegate? = nil
    
    private var trackingArea:NSTrackingArea? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    
    private func setMouseInside(value:Bool){
        if mouseInside != value{
            mouseInside = value
            self.needsDisplay = true
        }
    }
    
    
    private func ensureTrackingArea(){
        if trackingArea == nil{
            trackingArea = NSTrackingArea(rect: NSZeroRect, options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        }
    }
    
    override func updateTrackingAreas(){
        super.updateTrackingAreas()
        self.ensureTrackingArea()
        
        if !(self.trackingArea?.doesContain(trackingArea as Any))!{
            self.addTrackingArea(trackingArea!)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        self.mouseInside = true
        rowDelegate?.HoverTableRowEnter(row: rowIndex)
    }
    
    override func mouseExited(with event: NSEvent) {
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
            let gradient = HoverTableRowView.gradientWithTargetColor(targetColor: NSColor(red: 200.0 / 255, green: 200.0 / 255, blue: 200.0 / 255, alpha: 1))
            gradient.draw(in: self.bounds, angle: 0)
        }
    }
    
    
    
    private func separateRect()->NSRect{
        var separatorRect = self.bounds;
        separatorRect.origin.y = NSMaxY(separatorRect) - 1;
        separatorRect.size.height = 1;
        return separatorRect;
    }
    
    
    override func drawSeparator(in dirtyRect: NSRect) {
        Swift.print("separator")
    }
    
    
    
    override func drawSelection(in dirtyRect: NSRect){
        
       if self.selectionHighlightStyle != .none {
            let blue = NSColor.init(red: 17.0/255.0, green: 108.0/255.0, blue: 214.0/255.0, alpha: 1.0)
            blue.setFill()
            blue.setStroke()
            let selectionPath = NSBezierPath(rect: dirtyRect)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
    
    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        return .light
    }
}
