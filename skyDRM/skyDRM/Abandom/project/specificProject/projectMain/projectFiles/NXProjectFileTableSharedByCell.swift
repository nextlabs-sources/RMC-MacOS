//
//  NXProjectFileTableSharedByCell.swift
//  skyDRM
//
//  Created by bill.zhang on 3/2/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectFileTableSharedByCell: NSTableCellView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        circleLabel?.radius = (circleLabel?.bounds.width)!/2
    }
    
    @IBOutlet public var circleLabel : NXCircleText?
}
