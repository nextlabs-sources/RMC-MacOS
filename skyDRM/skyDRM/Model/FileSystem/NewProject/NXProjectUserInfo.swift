//
//  NXProjectUserInfo.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

class NXProjectUserInfo: NSObject {
    var       userId: Int?
    var  displayName: String?
    var        email: String?
    var creationTime: Date?
    
    override init() {
        super.init()
    }
}
