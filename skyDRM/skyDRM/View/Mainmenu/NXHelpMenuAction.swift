//
//  NXHelpMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXHelpMenuAction: NSObject {
    static let shared = NXHelpMenuAction()
    override private init() {
        super.init()
    }
  @objc   func gettingStarted() {
        if let url = URL(string: "https://help.skydrm.com/docs/mac/start/1.0/en-us/index.htm") {
            NSWorkspace.shared.open(url)
        }
        
    }
 @objc    func help() {
        if let url = URL(string: "https://help.skydrm.com/docs/mac/help/1.0/en-us/index.htm") {
            NSWorkspace.shared.open(url)
        }
        
    }
//  @objc   func checkforUpdate() {
//        // Check Upgrade
//        NXCheckUpgradeService.checkforUpdate() {
//            newVersion, downloadUrl, error in
//            
//            // Not modified
//            if let backendError = error as? BackendError {
//                switch backendError {
//                case .notModified:
//                    let message = NSLocalizedString("CHECK_UPGRADE_ALREADY_LASTEST", comment: "")
//                    NSAlert.showAlert(withMessage: message)
//                    return
//                default:
//                    break
//                }
//            }
//            
//            guard error == nil, let newVersion = newVersion, let downloadUrl = downloadUrl else {
//                // check upgrade failed
//                let message = NSLocalizedString("CHECK_UPGRADE_CHECK_FAILED", comment: "")
//                NSAlert.showAlert(withMessage: message)
//                return
//            }
//            
//            guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
//                // get current version failed
//                return
//            }
//            
//            if currentVersion >= newVersion {
//                // show already lastest
//                let message = NSLocalizedString("CHECK_UPGRADE_ALREADY_LASTEST", comment: "")
//                NSAlert.showAlert(withMessage: message)
//                return
//            }
//            
//            // show update alert
//            let message = NSLocalizedString("CHECK_UPGRADE_MESSAGE", comment: "")
//            let cancelTitle = NSLocalizedString("CHECK_UPGRADE_CANCEL", comment: "")
//            let confirmTitle = NSLocalizedString("CHECK_UPGRADE_UPDATE", comment: "")
//            NSAlert.show(with: nil, message: message, cancelTitle: cancelTitle, confirmTitle: confirmTitle) {
//                type in
//                if type == .sure {
//                    // download
//                    let url = URL(string: downloadUrl)!
//                    NSWorkspace.shared.open(url)
//                } else if type == .cancel {
//                    return
//                }
//            }
//            
//        }
//        
//    }
//    
//    private func showUpgradeUI(with newVersion: String?, downloadURL: String? = nil) {
//        if newVersion == nil {
//
//        } else {
//            let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
//            if newVersion == bundleVersion {
//
//            } else {
//
//            }
//        }
//    }
//    
//  @objc  func report() {
//        print("report")
//    }
}
