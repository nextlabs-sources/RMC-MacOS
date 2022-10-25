//
//  NXProjectRoot.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/18.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

class NXProjectRoot: NSObject {
    var            projects = [NXProjectModel]()
    var  createdByMeProjects = [NXProjectModel]()
    var otherCreatedProjects = [NXProjectModel]()
    
    override init() {
        super.init()
    }
}
