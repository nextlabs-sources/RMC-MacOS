//
//  NXRMCRepoItem.swift
//  skyDRM
//
//  Created by pchen on 12/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXRMCRepoItem: NSObject, NSCopying {
    var repoId = ""
    var name = ""
    var type: ServiceType = .kServiceUnset
    var isShared = false
    var isAuth = false
    var accountName = ""
    var accountId = ""
    var token = ""
    var creationTime = Date()
    
    override init(){
        super.init()
    }
    init(dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "type",
            let repoAlias = value as? String {
            self.type = ServiceType(rmsDescription: repoAlias)
        }
        else if key == "creationTime",
            let date = value as? Double {
            self.creationTime = Date(timeIntervalSince1970: date/1000)
        }
        else if ["name", "repoId", "isShared", "accountName", "accountId","token"].contains(key){
            super.setValue(value, forKey: key)
        }
    }
    func copy(with zone: NSZone? = nil) -> Any {
        let other = NXRMCRepoItem()
        other.repoId = repoId
        other.name = name
        other.type = type
        other.isShared = isShared
        other.accountName = accountName
        other.accountId = accountId
        other.token = token
        other.creationTime = creationTime
        return other
    }
    
    func correspondNXBoundService() -> NXBoundService {
        let returnValue = NXBoundService()
        if let boundService = DBBoundServiceHandler.shared.fetchBoundService(with: repoId, type: type) {
            DBBoundServiceHandler.formatNXBoundService(src: boundService, target: returnValue)
        } else {
            DBBoundServiceHandler.formatBoundService(from: self, to: returnValue)
        }
        
        return returnValue
        
    }
    init(from bs: NXBoundService) {
        super.init()
        
        repoId = bs.repoId
        accountName = bs.serviceAccount
        if let type = ServiceType(rawValue: bs.serviceType) {
            self.type = type
        }
        accountId = bs.serviceAccountId
        name = bs.serviceAlias
        token = bs.serviceAccountToken
        
    }
    
}


func ==(lhs: NXRMCRepoItem, rhs: NXRMCRepoItem) -> Bool {
    if lhs.type == rhs.type &&
        lhs.accountName == rhs.accountName {
        if lhs.type != .kServiceSharepointOnline {
            return true
        }
        else if lhs.accountId.lowercased() == rhs.accountId.lowercased() {
            return true
        }
    }
    return false
}
func !=(lhs: NXRMCRepoItem, rhs: NXRMCRepoItem) -> Bool {
    return !(lhs == rhs)
}
