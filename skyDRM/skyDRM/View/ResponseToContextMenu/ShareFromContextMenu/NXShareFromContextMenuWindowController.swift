//
//  NXShareFromContextMenuWindowController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 15/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXShareFromContextMenuWindowController: NSWindowController {

    static let sharedInstance = NXShareFromContextMenuWindowController(windowNibName: Constant.windowControllerNibName)
    
    fileprivate struct Constant {
        static let windowControllerNibName = "NXShareFromContextMenuWindowController"
        static let viewControllerXibName = "NXEncryptDecryptViewController"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.title = NSLocalizedString("APP_NAME", comment: "")
        _ = self.window?.styleMask.remove(.closable)
        
        let viewController = NXShareFromContextMenuViewController(nibName:  Constant.viewControllerXibName, bundle: nil)
        self.contentViewController = viewController
    }
    
}
