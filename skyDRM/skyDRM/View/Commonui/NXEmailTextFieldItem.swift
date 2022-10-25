//
//  NXEmailTextFieldItem.swift
//  macexample
//
//  Created by nextlabs on 2/8/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

class NXEmailTextFieldItem: NSCollectionViewItem {
    typealias KeyDownClosure = (NXEmailTextFieldInputType)->Void
    public var keydownClosure : KeyDownClosure?
    
    var inputTextField: NXEmailTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {

        inputTextField = NXEmailTextField(frame:NSZeroRect);
        view = inputTextField!;
        inputTextField.placeholderString = "Add email address"
        inputTextField.keyDownClosure = {(type) in
            self.keydownClosure!(type)
        }

        view.layer?.backgroundColor = NSColor.green.cgColor;
    }
    
    
}
