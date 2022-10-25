//
//  NXResultTagViewItem.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/4/10.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXResultTagViewItem: NSCollectionViewItem {
    @IBOutlet weak var tagLabel: NSTextField!
    @IBOutlet weak var labelsLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.tagLabel.wantsLayer = true
        
        self.labelsLabel.wantsLayer = true
        self.labelsLabel.cell?.wraps = true
        self.labelsLabel.usesSingleLineMode = false
        self.labelsLabel.cell?.isScrollable = false
        labelsLabel.maximumNumberOfLines = 0
//
//        self.view.layer?.backgroundColor = NSColor.orange.cgColor
//         self.labelsLabel.layer?.backgroundColor = NSColor.green.cgColor
//          self.tagLabel.layer?.backgroundColor = NSColor.blue.cgColor
    }
}
