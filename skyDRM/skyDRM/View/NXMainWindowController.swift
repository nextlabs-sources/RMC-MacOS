//
//  NXMainWindowController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 27/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

enum NXMainWindowType {
    case welcome
    case list
}
class NXMainWindowController: NSWindowController {

    var type: NXMainWindowType = .welcome
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.delegate = self
    }
}

extension NXMainWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("1")
    }
    
}
