//
//  NXOfflineFilesVC.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2018/12/27.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

class NXOfflineFilesVC: NXMyVaultViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        orderType = .allOffline
        updateTableHeaderView()
        
        initData(refresh: true)
    }
    
    override func initData(refresh: Bool) {
        self.data = NXMemoryDrive.sharedInstance.getOffline()
        reloadData(isRefresh: refresh)
    }
    
    private func updateTableHeaderView() {
        let array = self.fileTableView.tableColumns
        for column in array where column.identifier.rawValue == "sharedWith" {
            column.title = "FILE_INFO_TYPE".localized
        }
    }
    
  override func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .allOfflineAddFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .unOfflineAndRemoveFile)
    }
    
    @objc override func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .allOfflineAddFile {
            DispatchQueue.main.async {
                self.initData(refresh: false)
            }
        } else if notification.nxNotification == .unOfflineAndRemoveFile {
            DispatchQueue.main.async {
                if let file = notification.object as? NXSyncFile {
                    if let currentFile = self.getCurrentFile(file: file) {
                        self.removeFileWithFile(file: currentFile, isUpload: true)
                    }
                    
                }
            }
        }
    }
    
    override func makeUnOffline(file:NXSyncFile) {

        if file.file.sdmlBaseFile is SDMLShareWithMeFile {
            NXClient.getCurrentClient().sharedMakeFileOnline(file: file) {[weak self] (file, error) in
                if error == nil {
                    self?.removeFileWithFile(file: file!, isUpload: true)
                    NotificationCenter.post(notification: .updateSharedWithMeFile , object: file, userInfo: nil)
                }
            }
        } else if file.file.sdmlBaseFile is SDMLMyVaultFile {
            NXClient.getCurrentClient().makeFileOnline(file: file) {[weak self] (file, error) in
                if error == nil {
                    self?.removeFileWithFile(file: file!, isUpload: true)
                    NotificationCenter.post(notification: .updateMyVaultFile, object: file, userInfo: nil)
                }
            }
        } else if file.file.sdmlBaseFile is SDMLProjectFile {
            NXClient.getCurrentClient().makeFileOnlineOfProject(file: file) { (file, error) in
                if error == nil {
                    self.removeFileWithFile(file: file!, isUpload: true)
                    NotificationCenter.post(notification: .updateProjectFile, object: file, userInfo: nil)
                }
            }
        }  else if let workspaceFile = file.file as? NXWorkspaceFile {
            if NXClient.getCurrentClient().getWorkspace()?.unmarkFileOffline(file: workspaceFile) == nil {
                self.removeFileWithFile(file: file, isUpload: true)
            }
        }
    }
    
}


