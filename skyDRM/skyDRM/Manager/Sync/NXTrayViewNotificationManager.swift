//
//  NXTrayViewNotificationManager.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2019/7/17.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

class NXTrayViewNotificationManager: NSObject {
    static let shared = NXTrayViewNotificationManager()
    fileprivate var records = [NXFileRecord]()
    private override init() {
        super.init()
        
    
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadMyvalut)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadProject)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .startUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .stopUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploaded)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadFailed)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .removeFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .download)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .waitingUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .systembucketProtectSuccess)
        
    }
    
    func load() {
        records = NXDBManager.sharedInstance.getFileRecords().reversed()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
          YMLog("deinit")
     }
    
    open func getFileRecords() -> [NXFileRecord]{
        return records
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .logout {
        }else if notification.nxNotification == .removeFile {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    let record = NXFileRecord(file: file, type: .remove)
                    self.updateRecord(record)
                }
            }
        } else if notification.nxNotification == .uploadMyvalut || notification.nxNotification == .uploadProject || notification.nxNotification == .waitingUpload || notification.nxNotification == .systembucketProtectSuccess {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    if notification.nxNotification == .systembucketProtectSuccess{
                        let record = NXFileRecord(file: file, type: .systembucketProtect)
                        YMLog("i update coredate ===================>\(record.fileID)")
                        self.addOrUpdateRecord(record)
                    }else{
                        let record = NXFileRecord(file: file, type: .upload)
                        YMLog("i update coredate ===================>\(record.fileID)")
                        self.addOrUpdateRecord(record)
                    }
                }
            }
        } else if notification.nxNotification == .startUpload ||
            notification.nxNotification == .uploadFailed {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    let record = NXFileRecord(file: file, type: .upload)
                    self.updateRecord(record)
                }
            }
        } else if notification.nxNotification == .uploaded {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    let record = NXFileRecord(file: file, type: .upload)
                    record.fileStatus = .completed
                    self.updateRecord(record)
                }
            }
        } else if notification.nxNotification == .stopUpload {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    let record = NXFileRecord(file: file, type: .upload)
                    record.fileStatus = .pending
                    self.updateRecord(record)
                }
            }
        } else if notification.nxNotification == .download {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    if file.syncStatus?.status == .syncing {
                        let record = NXFileRecord(file: file, type:.download)
                        self.addOrUpdateRecord(record)
                    } else {
                        let record = NXFileRecord(file: file, type: .download)
                        self.updateRecord(record)
                    }
                }
            }
        }
         DispatchQueue.main.async {
            NotificationCenter.post(notification:.trayViewUpdated , object: nil)
        }
    }
}

extension NXTrayViewNotificationManager {
    
    fileprivate func isRecordExist(_ record: NXFileRecord) -> Bool {
        for r in self.records {
            if r == record {
                YMLog("exist:old\(r.fileID),,,new\(record.fileID)")
                return true
            }
        }
        return false
    }
    
    func addOrUpdateRecord(_ record: NXFileRecord) {
        if isRecordExist(record) {
            updateRecord(record)
        } else {
            addRecord(record)
        }
    }
    
    func updateRecord(_ record: NXFileRecord) {
        for (_, r) in self.records.enumerated() {
            if record.fileID == r.fileID {
                if r.fileStatus != record.fileStatus {
                    r.fileStatus = record.fileStatus
                    r.type = record.type
                    NXDBManager.sharedInstance.updateFileRecord(record)
                }
                break
            }
        }
        
    }
    
    func addRecord(_ record: NXFileRecord) {
        YMLog("trayview : i insert  a record in tableview\(record.fileID) ")
        self.records.insert(record, at: 0)
        NXDBManager.sharedInstance.addFileRecord(record)
        
    }
    
    func removeRecord(_ record: NXFileRecord) {
        for (index, r) in self.records.enumerated() {
            if record == r {
                self.records.remove(at: index)
                NXDBManager.sharedInstance.removeFileRecord(record)
                break
            }
        }
    }
}


