//
//  NXTrayOutlineMenuView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 05/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayOutlineMenuViewDelegate: NSObjectProtocol {
    func onShare(row: Int)
}

class NXTrayOutlineMenuView: NSView {
    var row: Int = -1
    weak var delegate: NXTrayOutlineMenuViewDelegate?
    private var shareBtn: NSButton?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        shareBtn = NSButton(frame: self.bounds)
        shareBtn?.setButtonType(.momentaryPushIn)
        shareBtn?.bezelStyle = .roundedDisclosure
        shareBtn?.isBordered = false
        shareBtn?.imageScaling = .scaleProportionallyDown
        shareBtn?.image = NSImage(named:  "share")
        shareBtn?.target = self
        shareBtn?.action = #selector(onClick)
        addSubview(shareBtn!)
    }
    
    @objc func onClick(sender: NSButton) {
        Swift.print("333")
    }
    
    
}
