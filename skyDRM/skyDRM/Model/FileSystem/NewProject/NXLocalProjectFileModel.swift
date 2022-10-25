//
//  NXLocalProjectFileModel.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/4/3.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

class NXLocalProjectFileModel: NXNXLFile {
    var    parentFileId: String?
    var       projectId: Int?
    var     projectName: String?
    override init() {
        super.init()
    }
}
