//
//  NXProjectOwner.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectOwner: NSObject, NSCoding, NSCopying {
    var userId: String?
    var name: String?
    var email: String?
    
    override init() {
        super.init()
    }
    
    init(with dic: [String: Any]) {
        if let userId = dic["userId"] as? Int {
            self.userId = "\(userId)"
        }
        
        name = (dic["name"] != nil ? dic["name"]: dic["displayName"]) as? String
        
        if let email = dic["email"] as? String {
            self.email = email
        }
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.userId, forKey: "userId")
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.email, forKey: "email")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.userId = aDecoder.decodeObject(forKey: "userId") as? String
        self.name = aDecoder.decodeObject(forKey: "name") as? String
        self.email = aDecoder.decodeObject(forKey: "email") as? String
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let other = NXProjectOwner()
        other.userId = userId
        other.name = name
        other.email = email
        return other
    }
    
}
