//
//  NXCommonInfo.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 09/05/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation
import Alamofire
import SDML

enum NXListType: String {
    case outbox
    case allOffline
    case sharedWithMe
    case myVault
    case projectFile
    case project
}

class NXClientUser: NSObject {
    
    static let shared = NXClientUser()
    
    func setLoginUser(tenant: NXTenant?, user: NXUser?) {
        self.tenant = tenant
        self.user = user
    }
    
    private(set) var tenant: NXTenant?
    private(set) var user: NXUser? {
        willSet {
            if newValue == nil {
                networkManager.stopListening()
                NXDBManager.sharedInstance.removeCoreDataController()
                NotificationCenter.post(notification: .logout, object: nil)
                NXMemoryDrive.sharedInstance.unload()
            }
        }
        didSet {
            if user != nil {
                isOnline = networkManager.isReachable
                networkManager.startListening {  [weak self] status in
                    if case NetworkReachabilityManager.NetworkReachabilityStatus.reachable = status  {
                        self?.isOnline = true
                    } else {
                        self?.isOnline = false
                    }
                }
                
                // Load DB.
                if let tenant = tenant, let user = user {
                    NXDBManager.sharedInstance.loadCoreDataController(tenant: tenant, user: user)
                }
                
                NotificationCenter.post(notification: .login, object: nil)
                
                NXTrayViewNotificationManager.shared.load()
                
                // Start pending tasks.
                // open file
                let openFilePaths = PendingTask.sharedInstance.getFilePaths(with: .openFile)
                let filePaths = openFilePaths.flatMap() { $0 }
                for filePath in filePaths {
                    NXFileRenderManager.shared.viewLocal(path: filePath)
                }
                _ = PendingTask.sharedInstance.removeAll()
                
                setting = NXPreferenceSetting(user: self)
                
                // save myDrive repo id for viewing remote myVault file
                NXClient.getCurrentClient().getMyVaultRepoDetail(){(result, error) in
                    guard let repoId = result?.getRepoID()  else {
                        return
                    }
                    NXCommonUtils.saveLocalDriveRepoId(repoId:repoId)
                }
            }
        }
    }
    
    @objc dynamic var storage: NXMyDriveStorage?
    
    /// Network status.
    @objc dynamic var isOnline = true
    var networkManager: NetworkReachabilityManager = NetworkReachabilityManager()!
    
    var setting: NXPreferenceSetting!
}

struct NXPreferenceSetting {
    struct Constant {
        static let kUserPreference    = "UserPreference.plist"
        static let kListSortType      = "listSortType"
        static let kListSortAscending = "ascending"
        
        static let KIsAutoUpload = "isAutoUpload"
        static let kIsUploadLeaveCopy = "isUploadLeaveCopy"
        static let kIsAutoLaunch = "isAutoLaunch"
    }
    
    private var isAutoUpload: Bool
    private var isUploadLeaveCopy: Bool
    private var isAutoLaunch: Bool
    
    private weak var user: NXClientUser?
    
    init(user: NXClientUser) {
        self.user = user
        
        // Default setting.
        isAutoUpload = true
        isUploadLeaveCopy = false
        isAutoLaunch = false
        
        let path = getUserPreferencePath()
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        } else {
            if let value = loadIsAutoUpload() {
                isAutoUpload = value
            }
            if let value = loadIsUploadLeaveCopy() {
                isUploadLeaveCopy = value
            }
            
            isAutoLaunch = loadIsAutoLaunch()
        }
    }
}

/// Getter and setter methods.
extension NXPreferenceSetting {
    func getIsAutoUpload() -> Bool {
        return isAutoUpload
    }
    
    func getIsAutoLaunch() -> Bool {
        return isAutoLaunch
    }
    
    func getIsUploadLeaveCopy() -> Bool {
        return isUploadLeaveCopy
    }
    
    mutating func setIsAutoUpload(value: Bool) {
        if value == self.isAutoUpload {
            return
        }
        
        self.isAutoUpload = value
        set(key: Constant.KIsAutoUpload, value: value)
    }
    
    mutating func setIsUploadLeaveCopy(value: Bool) {
        if value == self.isUploadLeaveCopy {
            return
        }
        
        self.isUploadLeaveCopy = value
        set(key: Constant.kIsUploadLeaveCopy, value: value)
    }
    
    mutating func setIsAutoLaunch(value: Bool) {
        if value == self.isAutoLaunch {
            return
        }
        
        self.isAutoLaunch = value
        set(key: Constant.kIsAutoLaunch, value: value)
    }
}

extension NXPreferenceSetting {
    /// path: ~/Library/Application Support/'BundleID'/'tenantID'/'userID'/userPreference.plist
    private func getUserPreferencePath() -> String {
        guard let tenant = self.user?.tenant, let user = self.user?.user else {
            return ""
        }
        
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.last!
        let bundleID = Bundle.main.bundleIdentifier!
        let router = tenant.routerURL
        let routerId = (URL(string: router)?.host) ?? ""
        
        let path = appSupportURL.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent(routerId, isDirectory: true).appendingPathComponent(tenant.tenantID, isDirectory: true).appendingPathComponent(user.userID, isDirectory: true).appendingPathComponent(Constant.kUserPreference, isDirectory: false).path
        
        return path
    }
    
    private func loadIsAutoUpload() -> Bool? {
        if let value = load(key: Constant.KIsAutoUpload) as? Bool {
            return value
        }
        
        return nil
    }
    
    private func loadIsUploadLeaveCopy() -> Bool? {
        if let value = load(key: Constant.kIsUploadLeaveCopy) as? Bool {
            return value
        }
        
        return nil
    }
    
    private func loadIsAutoLaunch() -> Bool {
        if let value = load(key: Constant.kIsAutoLaunch) as? Bool {
            return value
        }
        
        return false
    }
    
    private func load(key: String) -> Any? {
        let path = getUserPreferencePath()
        if let dic = NSDictionary.init(contentsOfFile: path),
            let result = dic.object(forKey: key) as? Bool{
            return result
        }
        
        return nil
    }
    
    private func set(key: String, value: Any) {
        let path = getUserPreferencePath()
        let dic = NSMutableDictionary.init(contentsOfFile: path) ?? NSMutableDictionary()
        dic.setValue(value, forKey: key)
        dic.write(toFile: path, atomically: true)
    }
}
