//
//  FileMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXFileMenuAction: NSObject {
    static let shared = NXFileMenuAction()
    override private init() {
        super.init()
    }
   @objc func openFile() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.openFile()
        }
    }
 @objc   func protectFile() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.protectFile()
        }
    }
  @objc  func shareFile() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.shareFile()
        }
    }
  @objc  func uploadFile() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController,
            let uploadBtn = vc.operationViewController.uploadBtn,
            let action = uploadBtn.action {
            uploadBtn.setNextState()
            vc.operationViewController.perform(action, with: uploadBtn)
        }
    }
    
  @objc  func stopUpload() {
    if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController,
        let uploadBtn = vc.operationViewController.uploadBtn,
        let action = uploadBtn.action {
        uploadBtn.setNextState()
        vc.operationViewController.perform(action, with: uploadBtn)
    }
        
    }
 @objc   func deleteFile() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.removeFile()
        }
    }
 @objc   func getInfo() {
    if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.viewFileInfo()
        }
    }
//@objc    func getActivityLog() {
//        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
//            guard let fileListView = vc.fileListView else {
//                return
//            }
//            let files = fileListView.selectedFiles
//            if files.isEmpty == false {
//                fileListView.fileOperation(type: .logProperty, file: files[0])
//            }
//        }
//        else if let projectvc = NSApplication.shared.mainWindow?.contentViewController as? NXSpecificProjectViewController {
//            guard let fileView = projectvc.filesView else {
//                return
//            }
//            let files = fileView.selectedFiles
//            if files.isEmpty == false {
//                fileView.fileOperation(type: .logProperty, file: files[0])
//            }
//        }
//        else if (NSApplication.shared.mainWindow?.windowController as? NXNormalFileRenderWindowController) != nil {
//        }
//        else if (NSApplication.shared.mainWindow?.windowController as? NXHPSFileRenderWindowController) != nil {
//        }
//    }
    
   @objc func signout() {
    
        let message: String
        if NXClient.getCurrentClient().isDownloadOrUpload() {
            message = "MENU_SIGNOUT_TIPS_2".localized
        } else {
            message = "MENU_SIGNOUT_TIPS".localized
        }
    
        NSAlert.showAlert(withMessage: message, confirmButtonTitle: NSLocalizedString("MENU_SIGNOUT_QUIT_BUTTON", comment: ""), cancelButtonTitle: NSLocalizedString("MENU_SIGNOUT_CANCEL_BUTTON", comment: ""), titleName: NSLocalizedString("TITLE_LOGOUT", comment: ""),dismissClosure: { type in
            if type == .sure {
                self.logout()
            }
        })
    }
    
    func logout() {
        // Logout user in sdk.
        NXClient.getCurrentClient().logout { (error) in
            if error != nil {
                print("Logout failed")
            }else{
                // Logout in app.
                NXClientUser.shared.setLoginUser(tenant: nil, user: nil)
            }
        }
    }
    
//    private func showProtectVC() {
//        let protectVC = NXHomeProtectVC()
//        NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(protectVC)
//    }
//    private func protectNormalFile() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        guard let fileListView = vc.fileListView else {
//            return
//        }
//        let files = fileListView.selectedFiles
//        if files.isEmpty == false {
//            fileListView.fileOperation(type: .protectFile, file: files[0])
//        }
//    }
//    private func showShareVC() {
//        let shareVC = NXHomeShareVC()
//        NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(shareVC)
//    }
//    private func shareNormalFile() {
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
//            return
//        }
//        guard let fileListView = vc.fileListView else {
//            return
//        }
//        let files = fileListView.selectedFiles
//        if files.isEmpty == false {
//            fileListView.fileOperation(type: .shareFile, file: files[0])
//        }
//    }
}

// MARK: Private methods.

extension NXFileMenuAction {
    private func isLogin() -> Bool {
        if NXClientUser.shared.user != nil {
            return true
        }
        
        return false
    }
    
    private func checkFile(operation: NXLocalListItemContextMenuOperation) -> Bool {
        if let selectedFile = getSelectedFile() {
            // Check is folder
            if selectedFile.file.isFolder {
                return false
            }
            
            if operation == .viewFile {
                if !selectedFile.file.fileStatus.contains(.downloading) && !selectedFile.file.fileStatus.contains(.uploading) {
                    return true
                }
            } else if operation == .viewFileInfo {
                if !selectedFile.file.fileStatus.contains(.downloading) && !selectedFile.file.fileStatus.contains(.uploading) &&
                    !selectedFile.file.fileStatus.contains(.opened) {
                    return true
                }
            } else if operation == .remove {
                if selectedFile.file.sdmlBaseFile is SDMLOutBoxFile {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func getSelectedFile() -> NXSyncFile? {
        guard let mainVC = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController else {
            return nil
        }
        
        if mainVC.clickType == .myVault {
            return mainVC.myVaultViewController.selectedFile
        } else if mainVC.clickType == .sharedWithMe {
            return mainVC.sharedWithMeVC.selectedFile
        } else if mainVC.clickType == .allOffline {
            return mainVC.offlineViewController.selectedFile
        } else if mainVC.clickType == .outBox {
            return mainVC.fileListViewController.selectedFile
        } else if mainVC.clickType == .project {
            return nil
        } else if mainVC.clickType == .projectFolder {
            return mainVC.projectFileVC.selectedFile
        } else if mainVC.clickType == .projectFile {
            return mainVC.projectNomarlFileVC.selectedFile
        } else if mainVC.clickType == .workspace {
            if let file = mainVC.workspace.selectedFile {
                let syncFile = NXSyncFile(file: file)
                syncFile.syncStatus = file.status
                return syncFile
            }
        }
        
        return nil
    }
}

extension NXFileMenuAction: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        let action = item.action
        
        if action == #selector(signout) {
            if let mainVC = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController {
                return !mainVC.isLoading
            } else {
                return isLogin()
            }
        }
        
        guard let mainVC = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController, mainVC.isLoading == false else {
            return false
        }
        
        if action == #selector(protectFile) {
            return true
        } else if action == #selector(shareFile) {
            if mainVC.clickType == .project || mainVC.clickType == .projectFile || mainVC.clickType == .projectFolder ||
            mainVC.clickType == .workspace {
                return false
            } else {
                return true
            }
        } else if action == #selector(uploadFile) {
            let uploadBtn = mainVC.operationViewController.uploadBtn
            if uploadBtn?.isEnabled == true, uploadBtn?.state == .off {
                return true
            }
            
        } else if action == #selector(stopUpload) {
            let uploadBtn = mainVC.operationViewController.uploadBtn
            if uploadBtn?.isEnabled == true, uploadBtn?.state == .on {
                return true
            }
            
        } else if action == #selector(openFile) {
            return checkFile(operation: .viewFile)
        } else if action == #selector(deleteFile) {
            return checkFile(operation: .remove)
        } else if action == #selector(getInfo) {
            return checkFile(operation: .viewFileInfo)
        }
        
        return false
    }
}
