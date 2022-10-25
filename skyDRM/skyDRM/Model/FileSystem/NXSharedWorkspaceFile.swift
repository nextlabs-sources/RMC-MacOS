//
//  NXSharedWorkspaceFile.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2022/1/19.
//  Copyright © 2022 nextlabs. All rights reserved.
//

import Foundation

class NXSharedWorkspaceFile: NXNXLFile {
    var           fileId: String?
    var         fileType: String?
    var      pathDisplay: String?
    var lastModifiedUser: NXProjectUserInfo?
    var            owner: NXProjectUserInfo?
    var isUploaded: Bool?
}
