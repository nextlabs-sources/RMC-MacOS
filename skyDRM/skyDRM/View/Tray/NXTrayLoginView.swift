//
//  NXTrayLoginView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import WebKit

class NXTrayLoginView: NSView {
    @IBOutlet weak var progress: NSProgressIndicator!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.set()
        __NSRectFill(bounds)
        // Drawing code here.
    }
}
