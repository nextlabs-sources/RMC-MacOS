//
//  NXNXLFile.swift
//  skyDRM
//
//  Created by pchen on 10/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import SDML
class NXNXLFile: NXFile {
    
    var sharedWith: String?
    var sharedOn: Int64?
    var isShared: Bool?
    var isRevoked: Bool?
    var isOwner: Bool?
    var isDeleted: Bool?
//    var customMetadata: NXMyVaultFileCustomMetadata?
    // detail
    var recipients: [String]?
    var comment: String?
    var protectedOn: Int64?
    var fileLink: String?
    var originFilePath: String?
    var isProject: Bool?
    var rights: [NXRightType]?
    var watermark: NXFileWatermark?
    var expiry: NXFileExpiry?
    var isTagFile: Bool?
    var tags: [String : [String]]?
    

    override init() {
        super.init()
    }
    
}
