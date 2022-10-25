//
//  NXTenant.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 04/05/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class NXTenant: NSObject {
    var tenantID: String
    var routerURL: String
    var rmsURL: String
    
    init(tenantID: String, routerURL: String, rmsURL: String) {
        self.tenantID = tenantID
        self.routerURL = routerURL
        self.rmsURL = rmsURL
        
        super.init()
    }
}
