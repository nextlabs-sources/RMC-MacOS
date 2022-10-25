//
//  NXBoundService.swift
//  skyDRM
//
//  Created by eric on 2017/1/10.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation
import Cocoa

class NXBoundService:NSObject,NSCoding{
    var serviceAccount:String = String()
    var serviceAccountId:String = String()
    var serviceAccountToken:String = String()
    var serviceAlias:String = String()
    var serviceIsAuthed:Bool = false
    var serviceIsSelected:Bool = false
    var serviceType:Int32 = -1
    var userId:String = String()
    var repoId:String = String()
    var objectID: NSManagedObjectID? = nil
    
    override init(){
        
    }
    
    init(account:String, accountId:String, accountToken:String, alias:String, isAuthed:Bool, isSelected:Bool, type:Int32, userId:String, repoId:String, objectId:NSManagedObjectID){
        self.serviceAccount = account
        self.serviceAccountId = accountId
        self.serviceAccountToken = accountToken
        self.serviceAlias = alias
        self.serviceIsAuthed = isAuthed
        self.serviceIsSelected = isSelected
        self.serviceType = type
        self.userId = userId
        self.repoId = repoId
        self.objectID = objectId
    }
    
    init(account:String, accountId:String, accountToken:String, alias:String, isAuthed:Bool, isSelected:Bool, type:Int32, userId:String, repoId:String){
        self.serviceAccount = account
        self.serviceAccountId = accountId
        self.serviceAccountToken = accountToken
        self.serviceAlias = alias
        self.serviceIsAuthed = isAuthed
        self.serviceIsSelected = isSelected
        self.serviceType = type
        self.userId = userId
        self.repoId = repoId
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.serviceAccount, forKey: "serviceAccount")
        aCoder.encode(self.serviceAccountId, forKey: "serviceAccountId")
        aCoder.encode(self.serviceAccountToken, forKey: "serviceAccountToken")
        aCoder.encode(self.serviceAlias, forKey: "serviceAlias")
        aCoder.encode(self.serviceIsSelected, forKey: "serviceIsSelected")
        aCoder.encode(self.serviceIsAuthed, forKey: "serviceIsAuthed")
        aCoder.encode(self.serviceType, forKey: "serviceType")
        aCoder.encode(self.userId, forKey: "userId")
        aCoder.encode(self.repoId, forKey: "repoId")
        aCoder.encode(self.objectID, forKey: "objectID")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.serviceAccount = (aDecoder.decodeObject(forKey: "serviceAccount") as? String)!
        self.serviceAccountId = (aDecoder.decodeObject(forKey: "serviceAccountId") as? String)!
        self.serviceAccountToken = (aDecoder.decodeObject(forKey: "serviceAccountToken") as? String)!
        self.serviceAlias = (aDecoder.decodeObject(forKey: "serviceAlias") as? String)!
        self.serviceIsSelected = (aDecoder.decodeObject(forKey: "serviceIsSelected") as? Bool)!
        self.serviceIsAuthed = (aDecoder.decodeObject(forKey: "serviceIsAuthed") as? Bool)!
        self.serviceType = Int32((aDecoder.decodeObject(forKey: "serviceType") as? Int)!)
        self.userId = (aDecoder.decodeObject(forKey: "userId") as? String)!
        self.repoId = (aDecoder.decodeObject(forKey: "repoId") as? String)!
        self.objectID = (aDecoder.decodeObject(forKey: "objectID") as? NSManagedObjectID)!
    }
}
