//
//  NXProjectFile.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectFile: NXProjectFileBase {
    var ownerByMe: Bool?
    var rights: [NXRightType]?
    var duid: String?
    var isNXL: Bool = true
    
}
