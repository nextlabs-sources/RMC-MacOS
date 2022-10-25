//
//  NXProjectTagCollectionHeaderView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/25.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectTagCollectionHeaderView: NSView {
    
    @IBOutlet weak var categoryNameLabel: NSTextField!
    
    @IBOutlet weak var selectTypeLabel: NSTextField!
    
    var headModel: NXProjectTagCategoryModel?
    

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToSuperview()
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
    
}
