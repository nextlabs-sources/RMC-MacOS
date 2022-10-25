//
//  NXEmailTextField.swift
//  macexample
//
//  Created by nextlabs on 2/9/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

enum NXEmailTextFieldInputType {
    case BackSpaceKey, DeleteKey, ReturnKey, SpaceKey
}

class NXEmailTextField: NSTextField {
    
    typealias KeyDownClosure = (NXEmailTextFieldInputType)->Void
    
    public var keyDownClosure:KeyDownClosure?;
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override init(frame:NSRect) {
        super.init(frame: frame)
    
        cell?.usesSingleLineMode = true;
        cell?.wraps = false;
        cell?.isScrollable = true;
        
        cell?.isBezeled = false;
        cell?.isBordered = false;
        cell?.isBordered = false;
        
        isBordered = false;
        
        delegate = self
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension NXEmailTextField : NSTextFieldDelegate {
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline) {
            //ENTER key
            Swift.print(String(describing: commandSelector));
            keyDownClosure!(.ReturnKey)
        }
        
        if commandSelector == #selector(NSResponder.deleteBackward) {
            
            if textView.string.utf8.count == 0 {
                //BACKSPACE key
                Swift.print(String(describing: commandSelector));
                keyDownClosure!(.BackSpaceKey)
            }
        }
        
        if commandSelector == #selector(NSResponder.deleteForward) {
            //DELETE key
            Swift.print(String(describing: commandSelector));
            keyDownClosure!(.DeleteKey)
        }
        return false
    }
}
