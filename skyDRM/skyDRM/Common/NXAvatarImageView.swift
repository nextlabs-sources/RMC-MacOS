//
//  NXAvatarImageView.swift
//  skyDRM
//
//  Created by xx-huang on 30/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXAvatarImageView: NSView {
    var circleText:NXCircleText?
    let itemSize:NSSize = NSSize(width: 64, height: 64)
    
    override init(frame frameRect: NSRect){
        super.init(frame: NSRect(origin: frameRect.origin, size: itemSize))
        // Do view setup here.
        circleText = NXCircleText()
        circleText?.frame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
        circleText?.backgroundColor = NSColor.blue
        circleText?.delegate = self
        self.addSubview(circleText!)
        
        circleText?.translatesAutoresizingMaskIntoConstraints = false
        
        let conLeft = circleText?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0)
        let conTop = circleText?.topAnchor.constraint(equalTo: self.topAnchor, constant: 0)
        let conWidth = circleText?.widthAnchor.constraint(equalToConstant: itemSize.width)
        let conHeight = circleText?.heightAnchor.constraint(equalToConstant: itemSize.height)
        NSLayoutConstraint.activate([conLeft!, conTop!, conWidth!, conHeight!])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    required init?(coder: NSCoder){
        super.init(coder: coder)
    }
}

extension NXAvatarImageView:MouseEventDelegate{
    func mouseEvent(entered event: NSEvent){
        NSCursor.pointingHand.set()
    }
    
    func mouseEvent(exited event: NSEvent){
        NSCursor.arrow.set()
    }
    
    func mouseEvent(down event: NSEvent){
    }
}

