//
//  NXFileRecord.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/8/28.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

enum NXRecordType: Int {
    case remove
    case upload
    case download
    case systembucketProtect
}

class NXFileRecord {
    var type: NXRecordType
    var filename: String
    var fileID: String
    var fileStatus: NXSyncState?
    
    init(type: NXRecordType, filename: String, fileID: String, fileStatus: NXSyncState?) {
        self.type = type
        self.filename = filename
        self.fileID = fileID
        self.fileStatus = fileStatus
    }
    
    init(file: NXSyncFile, type: NXRecordType) {
        self.type = type
        self.filename = file.file.name
        self.fileID = file.file.getNXLID()!
        self.fileStatus = file.syncStatus?.status
    }
}

extension NXFileRecord: Equatable {
    public static func == (lhs: NXFileRecord, rhs: NXFileRecord) -> Bool {
        if lhs.type == rhs.type, lhs.fileID == rhs.fileID {
            return true
        }
        
        return false
    }
}
