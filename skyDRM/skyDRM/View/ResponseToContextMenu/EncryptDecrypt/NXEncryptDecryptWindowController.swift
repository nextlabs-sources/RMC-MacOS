//
//  NXEncryptDecryptWindowController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 20/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXEncryptDecryptWindowController: NSWindowController {

    static let sharedInstance = NXEncryptDecryptWindowController(windowNibName: Constant.windowNibName)
    
    fileprivate struct Constant {
        static let windowNibName = "NXEncryptDecryptWindowController"
        static let encryptDecryptViewControllerXibName = "NXEncryptDecryptViewController"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.title = NSLocalizedString("TITLE_ENCRYPT_DECRYPT", comment: "")
        _ = self.window?.styleMask.remove(.closable)
        
        let viewController = NXEncryptDecryptViewController(nibName:  Constant.encryptDecryptViewControllerXibName, bundle: nil)
        self.contentViewController = viewController
    }
    
}


