//
//  NXProjectMember.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectMember: NSObject, NSCoding, NSCopying {
    var userId: String?
    var displayName: String?
    var email: String?
    var creationTime: TimeInterval = 0.0
    var inviterDisplayName: String?
    var inviterEmail: String?
    var avatarBase64: String?
    
    var project: NXProject?
    
    override init() {
        super.init()
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.userId, forKey: "userId")
        aCoder.encode(self.displayName, forKey: "displayName")
        aCoder.encode(self.email, forKey: "email")
        aCoder.encode(self.creationTime, forKey: "creationTime")
        aCoder.encode(self.inviterDisplayName, forKey: "inviterDisplayName")
        aCoder.encode(self.inviterEmail, forKey: "inviterEmail")
        aCoder.encode(self.avatarBase64, forKey: "avatarBase64")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.userId = aDecoder.decodeObject(forKey: "userId") as? String
        self.displayName = aDecoder.decodeObject(forKey: "displayName") as? String
        self.email = aDecoder.decodeObject(forKey: "email") as? String
        self.creationTime = (aDecoder.decodeObject(forKey: "creationTime") as? TimeInterval)!
        self.inviterDisplayName = aDecoder.decodeObject(forKey: "inviterDisplayName") as? String
        self.inviterEmail = aDecoder.decodeObject(forKey: "inviterEmail") as? String
        self.avatarBase64 = aDecoder.decodeObject(forKey: "avatarBase64") as? String
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let other = NXProjectMember()
        other.userId = userId
        other.displayName = displayName
        other.email = email
        other.creationTime = creationTime
        other.inviterEmail = inviterEmail
        other.inviterDisplayName = inviterDisplayName
        other.avatarBase64 = avatarBase64
        return other
    }
    
    /// use to equal
    override var hash : Int {
        return 0
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NXProjectMember,
            userId == object.userId,
            project == object.project {
            return true
        }
        
        return false
    }
}
