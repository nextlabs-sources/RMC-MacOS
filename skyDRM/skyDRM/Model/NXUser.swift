//
//  NXUser.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 04/05/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class NXUser: NSObject {
    var name: String
    var userID: String
    var email: String
    var userIdpType: Int
    var isPersonal: Bool
    
    init(name: String, userID: String, email: String, userIdpType: Int, isPersonal: Bool) {
        self.name = name
        self.userID = userID
        self.email = email
        self.userIdpType = userIdpType
        self.isPersonal = isPersonal
        
        super.init()
    }
}
