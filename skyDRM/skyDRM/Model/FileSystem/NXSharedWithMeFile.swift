//
//  NXSharedByMeFile.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/07/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

//import AppKit

class NXSharedWithMeFile: NXFile {
    struct Constant {
        static let kIsOwner = "isOwner"
    }
    
    var fileType: String?
    var sharedDate: String?
    var sharedBy: String?
    var transactionId: String?
    var transactionCode: String?
    var sharedLink: String?
    var rights: [NXRightType]?
    var comment: String?
    
    func getIsOwner() -> Bool {
        if let isOwner = extraInfor[Constant.kIsOwner] as? Bool {
            return isOwner
        } else {
            return false
        }
    }
    
    func setIsOwner(isOwner: Bool) {
        extraInfor[Constant.kIsOwner] = isOwner
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let file = object as? NXSharedWithMeFile,
            getNXLID() == file.getNXLID() {
            return true
        }
        
        return false
    }
}

