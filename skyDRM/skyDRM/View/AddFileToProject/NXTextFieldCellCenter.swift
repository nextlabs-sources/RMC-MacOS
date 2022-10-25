//
//  NXTextFieldCellCenter.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/21.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXTextFieldCellCenter: NSTextFieldCell {
    
    func adjustedFrameToVerticallyCenterText(frame: NSRect) -> NSRect {
        let offset = floor((NSHeight(frame)/2 - ((self.font?.ascender)! + (self.font?.descender)!)))
        return NSInsetRect(frame, 0.0, offset)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrameToVerticallyCenterText(frame: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }
    
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrameToVerticallyCenterText(frame: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrameToVerticallyCenterText(frame: cellFrame), in: controlView)
    }
}
