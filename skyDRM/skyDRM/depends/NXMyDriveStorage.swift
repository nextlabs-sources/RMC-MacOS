//
//  NXMyDriveStorage.swift
//  skyDRM
//
//  Created by qchen on 2020/2/6.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

class NXMyDriveStorage: NSObject {
    
    override init() {
        super.init()
    }
    
    init(used: Int64, total: Int64, myvault: Int64) {
        self.used = used
        self.total = total
        self.myvault = myvault
        
        super.init()
    }
    
    var used: Int64 = 0
    var total: Int64 = 0
    var myvault: Int64 = 0
    func reset() {
        used = 0
        total = 0
        myvault = 0
    }
}
