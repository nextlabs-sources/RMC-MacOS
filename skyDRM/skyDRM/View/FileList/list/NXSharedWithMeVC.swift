//
//  NXSharedWithMeVC.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2018/12/28.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXSharedWithMeVC: NXMyVaultViewController {
    

    
    override func viewDidLoad() {
        orderType = .sharedWithMe
        super.viewDidLoad()
        // Do view setup here.
        //set type of vc
        initData(refresh: false)
        updateTableHeaderView()
    }
    
    private func updateTableHeaderView() {
        let array = self.fileTableView.tableColumns
        for column in array where column.identifier.rawValue == "sharedWith" {
            column.title = "FILE_INFO_SHAREDBY".localized
        }
        
        for column in array where column.identifier.rawValue == "dateModified" {
            column.title = "FILE_INFO_SHAREDTIME".localized
        }
    }
    
    override func initData(refresh: Bool) {
        let files = NXMemoryDrive.sharedInstance.getShareWithMe()
        self.data = files
        
        reloadData(isRefresh: refresh)
    }
    
    
 override func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .updateSharedWithMeFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .refreshShareWithMe)
    }
    
    @objc override func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .updateSharedWithMeFile {
            if let file = notification.object as? NXSyncFile{
                DispatchQueue.main.async {
                    if let currentFile = self.getCurrentFile(file: file) {
                        self.updateMyVaultFile(file: currentFile, newFile: file)
                    }
                }
            }
        } else if notification.nxNotification == .refreshShareWithMe {
            DispatchQueue.main.async {
                self.initData(refresh: true)
            }
        }
    }
    
    override func makeUnOffline(file:NXSyncFile) {
        NXClient.getCurrentClient().sharedMakeFileOnline(file: file) {[weak self] (file, error) in
            if error == nil {
                NotificationCenter.post(notification: .unOfflineAndRemoveFile, object: file)
                self?.fileTableView.reloadData()
            }
        }
    }
    
    override func makeOffline(file: NXSyncFile) {
        let cellSelectedrow = fileTableView.selectedRow
        let cellCol = fileTableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("name"))
        let cellView = fileTableView.view(atColumn:cellCol,row: cellSelectedrow, makeIfNecessary: false)
        for view in (cellView?.subviews)! {
            if let progressBar = view as? NSProgressIndicator {
                progressBar.startAnimation(self)
                progressBar.isHidden = false
            }
        }
        
        file.file.fileStatus.insert(.downloading)
        NXClient.getCurrentClient().sharedMakeFileOffline(file: file) { [weak self] (file, error) in
            file?.file.fileStatus.remove(.downloading)
            if error == nil {
                self?.fileTableView.reloadData()
                NotificationCenter.post(notification: .download, object: file, userInfo: nil)
                NotificationCenter.post(notification: .allOfflineAddFile, object: file)
            } else {
                let message = "FILE_OPERATION_DOWNLOAD_FAILED".localized
                NSAlert.showAlert(withMessage: message)
                file?.syncStatus?.status = .pending
                self?.fileTableView.reloadData()
                NotificationCenter.post(notification: .download, object: file, userInfo: ["error":error!])
            }
        }
        self.fileTableView.reloadData()
        NotificationCenter.post(notification: .download, object: file, userInfo: nil)
    }
    
    override func removeFileAutomatic(file: NXSyncFile) {
        
    }
    
}
