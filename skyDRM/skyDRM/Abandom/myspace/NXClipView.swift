//
//  NXCollectionView.swift
//  skyDRM
//
//  Created by nextlabs on 13/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXClipView: NSClipView {

    var clipDelegate: NXClipDelegate? = nil
    
    override open func mouseDown(with event: NSEvent) {
        Swift.print("collection mouseDown")
        clipDelegate?.clicked()
        super.mouseDown(with: event)
    }
    override open func rightMouseUp(with event: NSEvent) {
        Swift.print("collection up")
        clipDelegate?.clicked()
        super.rightMouseUp(with: event)
    }
    override open func rightMouseDown(with event: NSEvent) {
        Swift.print("collection right down")
        clipDelegate?.clicked()
        super.rightMouseDown(with: event)
    }
    
}
