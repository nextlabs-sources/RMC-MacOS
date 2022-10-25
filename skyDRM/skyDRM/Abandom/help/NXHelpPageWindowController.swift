//
//  NXHelpPageWindowController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 08/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXHelpPageWindowController: NSWindowController {

    static let shared = loadFromNib()
    
    class func loadFromNib() -> NXHelpPageWindowController {
        let window = NSStoryboard(name: "NXHelpPage", bundle: nil).instantiateController(withIdentifier: "HelpPageWindow") as! NXHelpPageWindowController
        return window
    }
    func showWindow() {
        if let window = window {
            NSApplication.shared.runModal(for: window)
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        self.window?.delegate = self
        self.window?.styleMask.remove(.resizable)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}

extension NXHelpPageWindowController: NSWindowDelegate {
    func windowDidBecomeMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidBecomeKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.stopModal()
    }
}
