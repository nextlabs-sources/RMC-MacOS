//
//  NXPreferencesViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 16/01/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import ServiceManagement

class NXPreferencesViewController: NSViewController {
    
    let helperBundleName = "com.nxrmc.NXAutoLaunchHelper"

    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var launchOnStartupBtn: NSButton!
    @IBOutlet weak var uploadLeaveCopyBtn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        initView()
    }
    
    func initView() {
        backgroundView.wantsLayer = true
        backgroundView.layer?.borderWidth = 1
        backgroundView.layer?.borderColor = NSColor.init(colorWithHex: "#BDBDBD")!.cgColor
        backgroundView.layer?.backgroundColor = NSColor(colorWithHex: "#E3E3E3")?.cgColor
        
        launchOnStartupBtn.state = NXClientUser.shared.setting.getIsAutoLaunch() ? .on : .off
        uploadLeaveCopyBtn.state = NXClientUser.shared.setting.getIsUploadLeaveCopy() ? .on : .off
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = NXConstant.kTitle
        self.view.window?.delegate = self
        self.view.window?.styleMask.remove(.resizable)
    }
    
    @IBAction func onClickSaveButton(_ sender: Any) {
        save()
        self.presentingViewController?.dismiss(self)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
}

extension NXPreferencesViewController {
    fileprivate func save() {
        // Auto lauch.
        let isAutoLaunch = (launchOnStartupBtn.state == NSControl.StateValue.on) ? true : false
        NXClientUser.shared.setting.setIsAutoLaunch(value: isAutoLaunch)
        SMLoginItemSetEnabled(helperBundleName as CFString, isAutoLaunch)
        
        let isUploadLeaveCopy = (uploadLeaveCopyBtn.state == .on) ? true : false
        NXClientUser.shared.setting.setIsUploadLeaveCopy(value: isUploadLeaveCopy)
    }
}

extension NXPreferencesViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.presentingViewController?.dismiss(self)
    }
}
