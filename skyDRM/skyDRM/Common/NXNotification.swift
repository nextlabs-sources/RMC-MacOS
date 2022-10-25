//
//  NXNotification.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 04/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

extension NotificationCenter {
    static func post(notification: NXNotification, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: notification.notificationName, object: object, userInfo: userInfo)
    }
    
    static func add(_ observer: NSObject, selector: Selector, notification: NXNotification, object: Any? = nil) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: notification.notificationName, object: object)
    }
}

extension Notification {
    var nxNotification: NXNotification {
        var str = name.rawValue
        if let range = str.range(of: "NX") {
            str.removeSubrange(range)
        }
        return NXNotification(rawValue: str)!
    }
}

enum NXNotification: String {
    case protected
    case myVaultProtected
    case projectProtected
    case workspaceProtected
    
    case uploadMyvalut
    case uploadProject
    case waitingUpload
    case startUpload
    case stopUpload
    case uploaded
    case uploadFailed
    case systembucketProtectSuccess
    
    case download
    case downloaded
    case downloadFailed
    
    case login
    case logout
    case removeFile
    
    case addEmailItem
    
    case startRefresh
    case stopRefresh
    
    case refreshFinished
    case closeSelectFilePanel
    
    case updateMyVaultFile
    case allOfflineAddFile
    case unOfflineAndRemoveFile
    case updateSharedWithMeFile
    case updateProjectFile
    
    case trayViewUpdated
    
    case stopUploadAllFinish
    
    case refreshMyVault
    case refreshShareWithMe
    case refreshWorkspace
    
    case renderFinish
    
    case killLauncher
    
    var uniqueString: String {
        return "NX" + self.rawValue
    }
    
    var notificationName: Notification.Name {
        return Notification.Name(uniqueString)
    }
}
