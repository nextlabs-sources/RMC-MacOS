//
//  NXNumberTextField.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 29/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXNumberTextField: NSTextField {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stringValue = "0"
    }
    
    override func textDidChange(_ notification: Notification) {
        if let range = stringValue.range(of: "\\D+(\\.\\D*)?", options: .regularExpression) {
            stringValue.removeSubrange(range)
        }
        repeat {
            if stringValue.hasPrefix("0") {
                stringValue.remove(at: stringValue.startIndex)
            }
            else {
                break
            }
        }while(true)
        if stringValue.isEmpty {
            stringValue = "0"
        }
        
        super.textDidChange(notification)
    }
}

