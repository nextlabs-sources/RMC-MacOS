//
//  NXProjectFileModel.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation


class NXProjectFileModel: NXNXLFile {
    var         fileType: String?
    var            isNXL: Bool?
    var lastModifiedUser: NXProjectUserInfo?
    var            owner: NXProjectUserInfo?
    var           fileId: String?
    var       parentFileID: String?
    var         subfiles = [NXSyncFile]()
    var      pathDisplay: String?
    weak var          project: NXProjectModel?
    var       subFolders = [NXSyncFile]()
    
    override init() {
        super.init()
    }
    
}
