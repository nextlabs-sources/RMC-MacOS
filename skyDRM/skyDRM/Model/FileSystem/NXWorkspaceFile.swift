//
//  NXWorkspaceFile.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/20/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

class NXWorkspaceBaseFile: NXNXLFile {
    var subWorkspaceFiles: [NXWorkspaceBaseFile]? {
        get {
            return children as? [NXWorkspaceBaseFile]
        }
        set {
            children = newValue
        }
    }
    
    var id: String {
        return getNXLID()!
    }
}

class NXWorkspaceLocalFile: NXWorkspaceBaseFile {
    var parentID: String?
}

class NXWorkspaceFile: NXWorkspaceBaseFile {
    var           fileId: String?
    var         fileType: String?
    var      pathDisplay: String?
    var lastModifiedUser: NXProjectUserInfo?
    var            owner: NXProjectUserInfo?
    

    override var id: String {
        return fullServicePath
    }
}
