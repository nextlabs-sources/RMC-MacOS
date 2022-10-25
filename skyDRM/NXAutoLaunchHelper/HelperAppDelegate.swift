//
//  HelperAppDelegate.swift
//  NXAutoLaunchHelper
//
//  Created by Stepanoval (Xinxin) Huang on 2019/8/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let killLauncher = Notification.Name("NXkillLauncher")
}

@NSApplicationMain
class HelperAppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let mainID = "com.nxrmc.skyDRM"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainID }.isEmpty
        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: .killLauncher, object: mainID)
            
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("SkyDRM")
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(newPath)
        } else {
            self.terminate()
        }
        
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

