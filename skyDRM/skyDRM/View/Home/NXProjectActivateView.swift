//
//  NXProjectActivateVIew.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProjectActivateViewDelegate: NSObjectProtocol {
    func onActivate()
}

class NXProjectActivateView: NSView {

    weak var delegate: NXProjectActivateViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            wantsLayer = true
            layer?.backgroundColor = NSColor.white.cgColor
        }
    }
    @IBAction func onActivate(_ sender: Any) {
        delegate?.onActivate()
    }
    
}
