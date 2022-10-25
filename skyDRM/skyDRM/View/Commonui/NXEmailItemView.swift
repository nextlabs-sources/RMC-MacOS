//
//  NXEmailItemView.swift
//  macexample
//
//  Created by nextlabs on 2/8/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

class NXEmailItemView: NSView {
    
    typealias DeleteClosure = ()->Void
    public var deleteClosure : DeleteClosure?
    
    var isEnable = true {
        didSet {
            closeButton.isHidden = !isEnable
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    
    @IBAction func closeClicked(_ sender: Any) {
        deleteClosure!();
    }
}
