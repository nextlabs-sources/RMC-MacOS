//
//  NXExpiryNeverView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXExpiryNeverView: NSView {

    @IBOutlet weak var neverExpiry: NSTextField!
    @IBOutlet weak var accessText: NSTextField!
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var suffixLabel: NSTextField!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    fileprivate func location() {
        neverExpiry.stringValue = "FILE_RIGHT_EXPIRE".localized
        accessText.stringValue = "FILE_RIGHT_ACCESS".localized
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        location()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
    }
        
}
