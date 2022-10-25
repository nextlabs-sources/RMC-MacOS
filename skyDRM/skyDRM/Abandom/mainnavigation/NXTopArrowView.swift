//
//  NXTopArrowButton.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 16/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXTopArrowView: NSView {

    private let arrowWidth:CGFloat = 8
    private let arrowHeight:CGFloat = 8
    private let arrowImageGap:CGFloat = 4
    private let lineWidth:CGFloat = 4
    weak var delegate: NXTopArrowViewDelegate!
    @IBOutlet weak var image: NSImageView!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        let startPt = CGPoint(x: image.frame.width - arrowWidth + arrowImageGap, y: image.frame.height)
        let midPt = CGPoint(x: image.frame.width + arrowImageGap, y: image.frame.height)
        let endPt = CGPoint(x: image.frame.width + arrowImageGap, y: image.frame.height - arrowHeight)
        path.move(to: startPt)
        path.line(to: midPt)
        path.line(to: endPt)
        NSColor.black.setStroke()
        path.stroke()
        
    }
    override func viewWillMove(toSuperview newSuperview: NSView?) {
    }
    override func viewDidMoveToSuperview() {
        image.wantsLayer = true
        image.layer?.masksToBounds = true
        image.layer?.backgroundColor = BK_COLOR.cgColor
        image.imageScaling = .scaleAxesIndependently
    }
    func setImage(newImage: NSImage){
        DispatchQueue.main.async {
            self.image.layer?.cornerRadius = self.image.bounds.width/2
            self.image.image = newImage
        }
    }
    override func mouseDown(with event: NSEvent) {
        delegate?.topArrowViewMouseDown()
    }
}
