//
//  NXPlaceholderTextView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 12/07/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXPlaceholderTextView: NSTextView {
    var placeHolderString = "" {
        didSet {
            placeHolderAttrString = NSAttributedString(string: placeHolderString, attributes: [NSAttributedString.Key.foregroundColor : NSColor.lightGray])
            self.needsDisplay = true
        }
    }
    private var placeHolderAttrString: NSAttributedString = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor : NSColor.lightGray])
    
    override func becomeFirstResponder() -> Bool {
        self.needsDisplay = true
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        self.needsDisplay = true
        return super.resignFirstResponder()
    }
    
    
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        if self.string == "" && self != window?.firstResponder {
            placeHolderAttrString.draw(at: NSMakePoint(8, 8))
        }
    }
}
