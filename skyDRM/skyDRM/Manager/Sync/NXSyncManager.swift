//
//  NXSyncManager.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

protocol NXSyncManagerOperation {    
    func upload(file: NXSyncFile)
    func stopUpload(file: NXSyncFile)
    func stopUploadAll()
    
}

class NXSyncManager: NSObject {
    static let shared = NXSyncManager()
    private override init() {
        super.init()
        
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .logout {
            stopUploadAll()
        }
    }
    
    fileprivate lazy var uploadManager: NXUploadManager = {
        let manager = NXUploadManager()
        manager.delegate = self
        return manager
    }()

}

// MARK: - Public methods.

extension NXSyncManager: NXSyncManagerOperation {
    func upload(file: NXSyncFile) {
        if file.file.fileStatus.contains(.opened) || file.file.fileStatus.contains(.downloading) ||
            file.file.fileStatus.contains(.uploading) {
            return
        }
        
        // Change status.
        file.syncStatus = NXSyncFileStatus()
        
        if file.file is NXLocalProjectFileModel {
            NotificationCenter.post(notification: .uploadProject, object: file)
        } else if file.file is NXWorkspaceBaseFile {
        } else {
            NotificationCenter.post(notification:.uploadMyvalut , object: file)
        }
        
        uploadManager.upload(file: file)
    }
    
    func stopUpload(file: NXSyncFile) {
        guard file.syncStatus?.type == .upload, file.syncStatus?.status == .syncing else {
            return
        }
        
        uploadManager.cancel(file: file)
    }
    
    func stopUploadAll() {
        uploadManager.cancelAll()
    }
    
}

extension NXSyncManager: NXUploadManagerDelegate {
    func waitUploading(file: NXSyncFile) {
        file.syncStatus?.status = .pending
        NotificationCenter.post(notification: NXNotification.waitingUpload, object: file)
    }
    
    func startUploading(file: NXSyncFile) {
        debugPrint("\(Date()): \(String(describing: self))-startUploading")
        
        file.syncStatus?.status = .syncing
        
        file.file.fileStatus.insert(.uploading)
        
        NotificationCenter.post(notification: NXNotification.startUpload, object: file)
    }
    
    func cancelled(file: NXSyncFile) {
        debugPrint("\(Date()): \(String(describing: self))-cancelled")
        
        file.syncStatus = nil
        
        file.file.fileStatus.remove(.uploading)
        
        NotificationCenter.post(notification: .stopUpload, object: file)
    }
    
    func uploadFinish(file: NXSyncFile, newFile: NXFileBase?, error: Error?) {
        
        file.file.fileStatus.remove(.uploading)
        
        if let error = error {
            file.syncStatus?.status = .failed
            YMLog("fileName:\(file.file.name):==============\(error.localizedDescription)=================upload failed!!!")
            
            NotificationCenter.post(notification: .uploadFailed, object: file, userInfo: ["error": error])
        } else {
            YMLog("fileName:\(file.file.name):============================================upload success!!!")
            let newSyncFile = NXSyncFile(file: newFile!)
            let status = NXSyncFileStatus()
            status.status = newFile?.isOffline == true ? .completed : .pending
            status.type = .download
            newSyncFile.syncStatus = status
            
            // FIXME: No need post in main thread, but array in vc is not thread safe.
            DispatchQueue.main.async {
                NotificationCenter.post(notification: .uploaded, object: newSyncFile)
                if newFile?.isOffline == true {
                    NotificationCenter.post(notification: .allOfflineAddFile, object: newSyncFile)
                }
            }
            
        }
    }
    
}
