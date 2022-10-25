//
//  NXWindowsManager.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 02/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import Alamofire
import ServiceManagement

struct NXServerAddress {
    var router: String
    var tenant: String
}

class NXWindowsManager: NSObject {
    
    static let sharedInstance = NXWindowsManager()
    
    fileprivate var mainWindowController: NSWindowController!
    var mainWindow: NSWindow!
    var trayManager: NXTrayManager!
    fileprivate struct Constant {
        static let kMainStoryboardName = "Main"
        static let kMainWindowController = "mainWindowController"
        static let identifier_WelcomePage = "WelcomeViewController"
        static let kLocalMainViewNibName = "NXLocalMainViewController"
        static let helperBundleName = "com.nxrmc.NXAutoLaunchHelper"
    }
    
    var isMainWindowHasContent: Bool {
        return self.mainWindow.contentViewController != nil
    }
    
    var isMainWindowLoaded: Bool {
        var result = false
        if let vc = mainWindow.contentViewController as? NXLocalMainViewController, vc.loaded {
            result = true
        }
    
        return result
    }
    
    override init() {
        super.init()
        if let mainWindowController = NSStoryboard(name: Constant.kMainStoryboardName, bundle: nil).instantiateController(withIdentifier: Constant.kMainWindowController) as? NSWindowController {
            self.mainWindowController = mainWindowController
            self.mainWindow = mainWindowController.window!
            self.mainWindow.title = NXConstant.kTitle
        }
        
        trayManager = NXTrayManager()
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
    } 
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .logout {
            mainWindow.contentViewController = nil
            mainWindow.close()
        }
    }
}

// Public methods.
extension NXWindowsManager {
    func displayLaunchView() {
        
        //try to load login view controller
        displayFirstView()
    }
    
    func openMainWindow() {
        loadFileListView()
        showMainWindow()
    }
    
    func closeMainWindow() {
        mainWindow.orderOut(nil)
    }
    
    func setupTray() {
        trayManager.setup()
    }
    
    func showTray() {
        trayManager.showPopover()
    }
    
    func hideTray() {
        trayManager.closePopover()
    }
    
    func showMainWindow() {
        if mainWindow.contentViewController != nil {
            mainWindow.makeKeyAndOrderFront(nil)
        }
        
    }
}

// Private methods.
extension NXWindowsManager {
    fileprivate func displayFirstView() {
        let tenant = NXCacheManager.loadLastTenant()
        NXClient.getCurrentClient().initTenant(router: tenant.router, tenantID: tenant.tenant)
        if NXClient.getCurrentClient().isLogin() {
            let tenant = (NXClient.getCurrentClient().getTenant().0)!
            let user = (NXClient.getCurrentClient().getUser().0)!
            NXClientUser.shared.setLoginUser(tenant: tenant, user: user)
            self.trayManager.setup()
            self.openMainWindow()
        } else {
            if NXCommonUtils.loadAppHasUsed() == false {
                NXCommonUtils.saveAppHasUsed(bState: true)
                self.displayWelcomeView()
                SMLoginItemSetEnabled(Constant.helperBundleName as CFString, true)
            } else {
                loadLoginView()
            }
            
        }
        
    }
    fileprivate func loadFileListView() {
        if mainWindow.contentViewController as? NXLocalMainViewController != nil {
            return
        }
        
        let localMain = NXLocalMainViewController(nibName:  Constant.kLocalMainViewNibName, bundle: nil)
            // Fix bug 50318: Crash because delegate become dangling pointer in macOS 10.12.
            mainWindow.delegate = localMain
            
            mainWindow.contentViewController = localMain
        
    }
    
    fileprivate func displayWelcomeView() {
        loadWelcomeView()
        showMainWindow()
    }
    
    fileprivate func loadWelcomeView() {
        if let welcome = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: Constant.identifier_WelcomePage) as? WelcomeViewController {
            mainWindow.contentViewController = welcome
            welcome.delegate = self
        }
    }
    
    fileprivate func loadLoginView() {
        let setLoginUrlVC = NXSetLoginUrlViewController()
        mainWindow.contentViewController = setLoginUrlVC
        setLoginUrlVC.isNoWelcomeViewFrom = true
        setLoginUrlVC.delegate = self
        showMainWindow()
    }
}

extension NXWindowsManager: NXWelcomeVCDelegate, NXSetLoginUrlViewControllerDelegate {
    func didLoginFinished() {
        closeMainWindow()
        mainWindow.contentViewController = nil
    }
    
    func willLoginFinished() {
        trayManager.setup()
        trayManager.showPopover()
    }
    func showWindowWithClickDock() {
        if  !mainWindow.isMiniaturized && !mainWindow.isVisible {
           showTray()
        }
    }
}


