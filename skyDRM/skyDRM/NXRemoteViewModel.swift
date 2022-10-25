//
//  NXRemoteViewModel.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXRemoteViewModel: NSObject {
    var owner: Bool?
    var permissions: Int32?
    var cookies: [String]?
    var viewerURL: String?
    var duid: String?
    var membership: String?
    
    override init() {
        super.init()
    }
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "permissions", let value = value as? Int32 {
            permissions = value
        }else if key == "owner", let value = value as? Bool {
            owner = value
        }else {
            super.setValue(value, forKey: key)
        }
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}

class NXViewRepoParam: NSObject{
    var repoId: String = ""
    var pathId: String = ""
    var pathDisplay: String = ""
    var offset: String = "-480"
    var repoName: String = ""
    var repoType: String = ""
    var email: String = ""
    var parentTenantName: String = ""
    var lastModifiedDate: Double = 0
    var operations: Int = -1
    
    override init(){
        super.init()
    }
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}

class NXViewProjectParam: NSObject{
    var projectId: String = ""
    var pathId: String = ""
    var pathDisplay: String = ""
    var offset: String = "-480"
    var email: String = ""
    var parentTenantName: String = ""
    var lastModifiedDate: Double = 0
    var operatios: Int = 0
    
    override init(){
        super.init()
    }
    
    init(withDictionary dic: [String: Any]){
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
    }
    
    func setValue(_ value: Any?, forUnderfinedKey key: String){
        
    }
}


