//
//  NXSyncFile.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 06/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSyncFile: NSObject {
    var syncStatus: NXSyncFileStatus?
    
    var file: NXFileBase
    init(file: NXFileBase) {
        self.file = file
    }
}
