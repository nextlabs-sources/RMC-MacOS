//
//  NXNavTableView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/26.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXNavTableRowView: NSTableRowView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if isSelected == true {
            BK_COLOR.set()
            __NSRectFill(dirtyRect)
        }
    }
    
}
