//
//  NXMyVaultFileTableShareWithCellView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXMyVaultFileTableShareWithCellView: NSTableCellView {
    
     var strArray = [String]()
    
    @IBOutlet weak var multiCircleView: NXMultiCircleView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        multiCircleView.maxDisplayCount = 2
        multiCircleView.isLastDataMoreCount = true
        multiCircleView.data = strArray
        // Drawing code here.
    }
}
