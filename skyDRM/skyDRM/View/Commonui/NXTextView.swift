//
//  NXTextView.swift
//  SkyDrmUITest
//
//  Created by Walt (Shuiping) Li on 20/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTextViewDelegate: NSObjectProtocol {
    func onKeyEnter(range: NSRange) -> Bool
}

class NXTextView: NSTextView {
    
    weak var eventDelegate: NXTextViewDelegate?
    
    override func keyDown(with event: NSEvent) {
        if(event.keyCode == 36) // Click enter key
        {
            let range = selectedRange()
            _ = eventDelegate?.onKeyEnter(range: range)
        }
        else {
            super.keyDown(with: event)
        }
    }
}

