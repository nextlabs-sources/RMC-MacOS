//
//  MaskView.swift
//  MaskViewDemo
//
//  Created by pchen on 09/03/2017.
//  Copyright © 2017 CQ. All rights reserved.
//

import Cocoa

class MaskView: NSView {

    static let sharedInstance = MaskView()
    
    var color: NSColor = NSColor.gray {
        didSet {
            layer?.backgroundColor = color.cgColor
        }
    }
    
    var alpha: Float = 0.5 {
        didSet {
            alphaValue = CGFloat(alpha)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
    }
    
    override func viewDidMoveToSuperview() {
        wantsLayer = true
        layer?.backgroundColor = color.cgColor
        alphaValue = CGFloat(alpha)
        
        if superview != nil { addAutoLayout() }
        
    }
    
    func addAutoLayout() {
        self.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view": self]
        var allConstraints = [NSLayoutConstraint]()
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)
        allConstraints += hConstraints + vConstraints
        
        NSLayoutConstraint.activate(allConstraints)
        
    }
}
