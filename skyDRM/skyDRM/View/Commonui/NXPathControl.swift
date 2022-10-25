//
//  NXPathControl.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 25/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXPathControl: NSPathControl {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    public var textColor: NSColor = NSColor.black
    
    override var url: URL? {
        didSet {
            _ = self.pathComponentCells().map{ $0.textColor = textColor}
        }
    }
}
