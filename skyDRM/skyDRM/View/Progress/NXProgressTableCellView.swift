//
//  TableCellView.swift
//  TreeViewDemo
//
//  Created by pchen on 27/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

class NXProgressTableCellView: NSTableCellView {

    @IBOutlet weak var nameText: NSTextField!
    @IBOutlet weak var percentageText: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var cancelBtn: NSButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}
