//
//  NXCheckPermissionWindowController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 02/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXCheckPermissionWindowControllerDelegate: NSObjectProtocol {
    func windowClose(with file: NXFileBase?)
}

class NXCheckPermissionWindowController: NSWindowController {

    var file: NXFileBase?
    weak var delegate: NXCheckPermissionWindowControllerDelegate?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        self.window?.title = NSLocalizedString("TITLE_CHECK_PERMISSION", comment: "")
        // title bar transparent
        self.window?.titleVisibility = .hidden
        self.window?.titlebarAppearsTransparent = true
        self.window?.styleMask = .titled
        
        let viewController = NXCheckPermissionViewController()
        viewController.file = file
        viewController.delegate = self
        self.contentViewController = viewController
    }
    
}

extension NXCheckPermissionWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        delegate?.windowClose(with: file)
    }
}

extension NXCheckPermissionWindowController: NXCheckPermissionViewControllerDelegate {
    func close(with file: NXFileBase?) {
        self.window?.close()
    }
}
