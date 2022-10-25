//
//  SpecificProjectWindow.swift
//  skyDRM
//
//  Created by helpdesk on 2/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectWindow: NSWindowController, NSWindowDelegate {
    
    static let sharedInstance = loadFromNib()
    
    class func loadFromNib()->NXSpecificProjectWindow{
        let window = NSStoryboard(name:"SpecificProject", bundle: nil).instantiateController(withIdentifier:  "SpecificProjectWindow") as! NXSpecificProjectWindow
        return window
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
        self.window?.title = NSLocalizedString("TITLE_SPECIFIC_PROJECT", comment: "")
        
        NXMainMenuHelper.shared.onSpecificProjectViewHome()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func closeCurrentWindow(){
        if self.window?.isVisible == true {
            self.close()
        }
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
    }

}
