//
//  NXViewMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class NXViewMenuAction: NSObject {
    static let shared = NXViewMenuAction()
    override private init() {
        super.init()
    }
//   @objc func previous(){
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        guard let fileOperationBar = vc.fileListView?.fileOperationBar else {
//            return
//        }
//        fileOperationBar.seeViewedBack()
//    }
// @objc   func next() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        guard let fileOperationBar = vc.fileListView?.fileOperationBar else {
//            return
//        }
//        fileOperationBar.seeViewedForward()
//    }
//@objc    func refresh() {
//        guard let contentVC = NSApplication.shared.mainWindow?.contentViewController else {
//            return
//        }
//        if let vc = contentVC as? ViewController {
//            guard let fileListView = vc.fileListView else {
//                return
//            }
//            fileListView.fileOperationBarDelegate(type: .refreshClicked, userData: nil)
//        }
//        else if let projectvc = contentVC as? NXSpecificProjectViewController {
//            guard let fileView = projectvc.filesView else {
//                return
//            }
//            fileView.fileOperationBarDelegate(type: .refreshClicked, userData: nil)
//        }else if let vc = contentVC as? NXLocalMainViewController {
//            vc.fileListViewController?.refresh()
//        }
//    }
// @objc   func gotoMydrive() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        vc.view.window?.orderFront(nil)
//        vc.homeGotoMySpace(type: .cloudDrive, alias: "MyDrive")
//    }
//  @objc  func gotoMyvault() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        vc.view.window?.orderFront(nil)
//        vc.homeGotoMySpace(type: .myVault, alias: "MyVault")
//    }
//   @objc func gotoHome() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        if let vc = delegate.mainWindow?.contentViewController as? ViewController {
//            vc.view.window?.orderFront(nil)
//            vc.navButtonClicked(index: 0)
//        }
//        else if let vc = delegate.mainWindow?.contentViewController as? NXProjectActivateViewController {
//            vc.onCancel(vc)
//        }
//    }
//
    @objc func sortby() {
    }
    
  @objc  func sortbyFileName() {
    if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.sortByFileName()
        }
    }
  @objc  func sortbyLastModified() {
    if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.sortByLatsModifyTime()
        }
    }
@objc    func sortbyFileSize() {
    if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
        vc.sortBySize()
        }
    }
}

extension NXViewMenuAction: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        let action = item.action
        if action == #selector(sortby) {
            
            if let _ = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController {
                return true
            }
        }
        else if action == #selector(sortbyFileName) || action == #selector(sortbyLastModified) || action == #selector(sortbyFileSize) {
            if let mainVC = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController {
                if mainVC.clickType == .project {
                    return false
                } else if mainVC.clickType == .sharedWithMe {
                    if action == #selector(sortbyLastModified) {
                        return false
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        
        return false
    }
}
