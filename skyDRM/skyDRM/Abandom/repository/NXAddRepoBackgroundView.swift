//
//  NXAddRepoBackgroundView.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXAddRepoBackgroundView: NSView {

    private let crossWidth:CGFloat = 40
    private let crossHeight:CGFloat = 10
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let startColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)
        let endColor = NSColor(colorWithHex: "#70B55B", alpha: 1.0)
        let gradient = NSGradient(starting: startColor!, ending: endColor!)
        gradient?.draw(in: bounds, angle: -30)
        
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        let path = CGMutablePath()
        var startPt = CGPoint(x: (frame.width - crossWidth)/2, y: frame.height/2)
        var endPt = CGPoint(x: (frame.width + crossWidth)/2, y: frame.height/2)
        path.move(to: startPt)
        path.addLine(to: endPt)
        startPt = CGPoint(x: frame.width/2, y: (frame.height - crossWidth)/2)
        endPt = CGPoint(x: frame.width/2, y: (frame.height + crossWidth)/2)
        path.move(to: startPt)
        path.addLine(to: endPt)
        context?.addPath(path)
        context?.setStrokeColor(NSColor.white.cgColor)
        context?.setLineWidth(crossHeight/2)
        context?.strokePath()
        context?.restoreGState()
        // Drawing code here.
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
    }

}
