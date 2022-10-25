//
//  SDOperation.swift
//  skyDRM
//
//  Created by pchen on 13/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import Alamofire

class NXMyDriveRestOperation: NXBaseRestOperation {
    
    override init(withRestAPI api: RestAPI, from: String? = nil, toFolder: String? = nil) {
        super.init(withRestAPI: api, from: from, toFolder: toFolder)
    }
}
