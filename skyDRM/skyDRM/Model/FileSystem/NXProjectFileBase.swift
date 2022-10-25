//
//  NXProjectFileBase.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 13/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// Abstract class
class NXProjectFileBase: NXFileBase {
    var fileId: String?
    var projectId: String?
    var projectName: String?
    var creationTime: TimeInterval?
    var owner: NXProjectOwner?
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NXProjectFileBase,
            projectId == object.projectId,
            fullServicePath == object.fullServicePath {
            return true
        }
        return false
    }
}
