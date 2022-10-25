//
//  AppDelegate.swift
//  skyDRM
//
//  Created by eric on 2016/12/29.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

import Cocoa
//import SwiftyDropbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    var mainWindow: NSWindow?
    var managedObjectContext: NSManagedObjectContext? {
        get {
            // FIXEM: do you need managedobject?
//            return NXLoginUser.sharedInstance.dataController?.managedObjectContext
            return nil
        }
    }
    // Go to SkyDRM Descktop
    let isAutoCheckUpgrade = true
    
    var didFinish = false
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        debugPrint("进入App")
        terminateDuplicateApp()
        
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        didFinish = true
        
        // Insert code here to initialize your application
        let servericeProvider = ServicesProvider()
        NSApp.servicesProvider = servericeProvider
        NSUpdateDynamicServices()
        
        NSUserNotificationCenter.default.delegate = self
        if #available(OSX 10.14, *) {
            NSApp.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        } else {
            // Fallback on earlier versions
        }
        
        // Setting menu.
        NXMainMenuHelper.shared.logoutMenu()
        
        // Display window
        NXWindowsManager.sharedInstance.displayLaunchView()
        
        killLauncher()
    }
    
    func exceptionHandler(exception: NSException) {
            let arr = exception.callStackSymbols//得到当前调用栈信息
            let reason = exception.reason//非常重要，就是崩溃的原因
            let name = exception.name//异常类型
            try? FileManager.default.removeItem(at: NXCommonUtils.getTempFolder()!)
            YMLog("exception type : \(name) \n crash reason : \(reason ?? "没有信息") \n call stack info : \(arr)");
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
        // Fix Bug 68120 - crash because of access wild pointer.
        NXInitHPSCpp2OC.deInitWorld()
        
        // Insert code here to tear down your application
        let tempFolder = NXCommonUtils.getTmpOpenFilePath()!.path
        if FileManager.default.fileExists(atPath: tempFolder) {
            do {
                try FileManager.default.removeItem(atPath: tempFolder)
            } catch {
                
            }
        }
        
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NXWindowsManager.sharedInstance.showWindowWithClickDock()
        return true
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext?.undoManager
    }
    
    internal func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        guard let managedObjectContext = managedObjectContext else {
            return .terminateNow
        }
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .terminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == NSApplication.ModalResponse.alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool
    {
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let services = ServicesProvider()
        services.handle(type: .openFile, paths: filenames)
    }

}

extension AppDelegate {
    /// Only one instance running at the same time
    fileprivate func terminateDuplicateApp() {
        let applications = NSWorkspace.shared.runningApplications.filter() { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
        if applications.count > 1 {
            if let url = applications[0].bundleURL {
                let _ = try? NSWorkspace.shared.launchApplication(at: url, options: [], configuration: [:])
            }
            
            // Fail to activate the first one, so not use yet.
            
            NSApp.terminate(nil)
            
        }
    }
    
    /// Check upgrade with server, remove in the future when upload to app store.
//    func checkUpgradeUsingServer() {
//        if isAutoCheckUpgrade {
//            NXCheckUpgradeService.checkforUpdate() {
//                newVersion, downloadUrl, error in
//                
//                // Not modified
//                if let backendError = error as? BackendError {
//                    switch backendError {
//                    case .notModified:
//                        return
//                    default:
//                        break
//                    }
//                }
//                
//                guard error == nil, let newVersion = newVersion, let downloadUrl = downloadUrl else {
//                    return
//                }
//                
//                guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
//                    // get current version failed
//                    return
//                }
//                
//                if currentVersion >= newVersion {
//                    // show already lastest
//                    return
//                }
//                
//                if let ignoreVerson = UserDefaults.standard.object(forKey: "UpgradeIgnoreVersion") as? String,
//                    ignoreVerson == newVersion {
//                    // skip
//                    return
//                }
//                
//                // show update alert
//                let message = NSLocalizedString("CHECK_UPGRADE_MESSAGE", comment: "")
//                let cancelTitle = NSLocalizedString("CHECK_UPGRADE_CANCEL", comment: "")
//                let confirmTitle = NSLocalizedString("CHECK_UPGRADE_UPDATE", comment: "")
//                let otherTitle = NSLocalizedString("CHECK_UPGRADE_IGNORE", comment: "")
//                NSAlert.show(with: nil, message: message, cancelTitle: cancelTitle, confirmTitle: confirmTitle, otherTitle: otherTitle) {
//                    type in
//                    if type == .sure {
//                        // download
//                        let url = URL(string: downloadUrl)!
//                        NSWorkspace.shared.open(url)
//                    } else if type == .cancel {
//                        return
//                    } else if type == .other {
//                        // save ignore version
//                        UserDefaults.standard.setValue(newVersion, forKey: "UpgradeIgnoreVersion")
//                    }
//                }
//                
//            }
//        }
//    }
    
    func killLauncher() {
        let launcherID = "com.nxrmc.NXAutoLaunchHelper"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherID }.isEmpty
        if isRunning {
            DistributedNotificationCenter.default().post(name: NXNotification.killLauncher.notificationName, object: Bundle.main.bundleIdentifier!)
        }
    }
}

