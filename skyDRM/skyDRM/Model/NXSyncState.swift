//
//  NXSyncState.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 06/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSyncFileStatus: NSObject {
    var status: NXSyncState = .pending
    var type: NXSyncType = .upload
}

enum NXSyncType: Int {
    case upload = 0
    case download
}

enum NXSyncState: Int {
    case waiting
    case pending
    case syncing
    case failed
    case completed
}
