//
//  NXRepoTableRow.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/17.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXRepoTableRowDelegate: NSObjectProtocol {
    func drawSelection(with rowView: NXRepoTableRow)
    func drawUnSelection(with rowView: NXRepoTableRow)
}

class NXRepoTableRow: NSTableRowView {

    weak var delegate: NXRepoTableRowDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if self.isSelected == false {
            delegate?.drawUnSelection(with: self)
        }
    }
    
    override func drawSelection(in dirtyRect: NSRect){
        if self.selectionHighlightStyle != .none{
            let selectionRect = NSInsetRect(self.bounds, 5.5, 5.5)
            NSColor(calibratedWhite: 0.72, alpha: 1.0).setStroke()
            NSColor(calibratedWhite: 0.82, alpha: 1.0).setFill()
         
            let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 2, yRadius: 2)
            selectionPath.fill()
            selectionPath.stroke()
            
            delegate?.drawSelection(with: self)
        }
    }
}
