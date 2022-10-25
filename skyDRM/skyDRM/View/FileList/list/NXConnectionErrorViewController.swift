//
//  NXConnectionErrorViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 16/01/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXConnectionErrorViewController: NSViewController {
    @IBOutlet weak var closeBtn: NSButton!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = NSLocalizedString("CONNECTION_ERROR_WINDOW_TITLE", comment: "")
        self.view.window?.styleMask = [.titled, .closable]
        self.view.window?.backgroundColor = NSColor.white
        self.view.window?.titlebarAppearsTransparent = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        closeBtn.wantsLayer = true
        closeBtn.layer?.cornerRadius = 5
        closeBtn.layer?.borderWidth = 0.3
        
        self.view.window?.delegate = self
        // Do view setup here.
    }
    @IBAction func onClose(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
    
}

extension NXConnectionErrorViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.presentingViewController?.dismiss(self)
    }
}
