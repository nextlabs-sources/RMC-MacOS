//
//  NXHelpPageViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 08/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXHelpPageViewController: NSViewController {

    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var companyInfo: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        NotificationCenter.add(self, selector: #selector(logout(_:)), notification: .logout, object: nil)
    }
    
    @objc func logout(_ notification: Notification) {
        if notification.nxNotification == .logout {
            self.view.window?.close()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.title = NXConstant.kTitle

        let BundleVersion:String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String?
        
        if let bundleVersion = BundleVersion {
            versionLabel.stringValue = "SkyDRM Desktop Version \(bundleVersion)"
        }
        
        let gesture = NSClickGestureRecognizer()
        gesture.target = self
        gesture.action = #selector(goCompanyInfo)
        
        companyInfo.addGestureRecognizer(gesture)
    }
    
    @objc func goCompanyInfo() {
        if let url = URL(string: "https://www.nextlabs.com") {
            NSWorkspace.shared.open(url)
        }
        
    }
    
}
