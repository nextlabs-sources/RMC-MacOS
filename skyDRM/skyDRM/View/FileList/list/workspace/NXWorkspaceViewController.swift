//
//  NXWorkspaceViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/30/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

class NXWorkspaceViewController: NXBaseFileViewController {
    
    deinit {
        removeObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addObserver()
        initEmptyView()
        initData()
    }
    
    private func initEmptyView() {
        listEmptyView.isHidden = true
        if let imageView = listEmptyView.viewWithTag(0) as? NSImageView {
            imageView.image = NSImage(named: "folder_blue")
        }
        if let label = listEmptyView.viewWithTag(1) as? NSTextField {
            label.stringValue = "FILE_INFO_EMPTY_FOLDER".localized
        }
    }
    
    private func initData() {
        let files = NXMemoryDrive.sharedInstance.getWorkspace()
        loadData(folder: nil, files: files)
    }
    
    private func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .refreshWorkspace)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .workspaceProtected)
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .refreshWorkspace {
            initData()
        } else if notification.nxNotification == .workspaceProtected {
            guard let file = notification.object as? NXFileBase else {
                return
            }
            
            if file.parent == folder {
                let files: [NXFileBase]
                if folder == nil {
                    files = NXMemoryDrive.sharedInstance.getWorkspace()
                } else {
                    files = folder!.children ?? []
                }
                
                loadData(folder: folder, files: files)
            }
        }
    }
    
}

// MARK: - File Operation.

extension NXWorkspaceViewController {
    override func markOffline(file: NXFileBase) {
        super.markOffline(file: file)
        
        if let workspaceFile = file as? NXWorkspaceFile {
            _ = NXClient.getCurrentClient().getWorkspace()?.markFileOffline(file: workspaceFile, completion: { (error) in
                file.fileStatus.remove(.downloading)
                if error != nil {
                    let message = "FILE_OPERATION_DOWNLOAD_FAILED".localized
                    NSAlert.showAlert(withMessage: message)
                    file.status?.status = .pending
                }
                
                DispatchQueue.main.async {
                    self.fileTableView.reloadData()
                }
                
                NotificationCenter.post(notification: .download, object: file, userInfo: nil)
            })
        }
    }
    
    override func unmarkOffline(file: NXFileBase) {
        guard let workspaceFile = file as? NXWorkspaceFile else {
            return
        }
        
        if NXClient.getCurrentClient().getWorkspace()?.unmarkFileOffline(file: workspaceFile) == nil {
            NotificationCenter.post(notification: .unOfflineAndRemoveFile, object: file)
            self.fileTableView.reloadData()
        }
    }
}
