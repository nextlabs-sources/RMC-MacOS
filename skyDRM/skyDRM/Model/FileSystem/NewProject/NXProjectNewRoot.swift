//
//  NXProjectNewRoot.swift
//  skyDRM
//
//  Created by william.zhao on 8/15/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectNewRoot: NSObject {
    var chidren = [NXProjectModel]()
    var createByMe = [NXProjectModel]()
    var createByOthers = [NXProjectModel]()
    override init() {
        super.init()
    }
}
