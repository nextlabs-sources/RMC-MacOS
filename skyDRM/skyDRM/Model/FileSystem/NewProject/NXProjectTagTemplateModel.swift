//
//  NXProjectTagTemplateModel.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

class NXProjectTagTemplateModel: NSObject {
    var maxCategoryNum: Int?
    var    maxLabelNum: Int?
    var     categories: [NXProjectTagCategoryModel]?
    
    override init() {
        super.init()
    }
}


class NXProjectTagCategoryModel: NSObject {
    var        name: String?
    var multiSelect: Bool?
    var   mandatory: Bool?
    var      labels: [NXProjectTagLabel]?
    
    override init() {
        super.init()
    }
}

class NXProjectTagLabel: NSObject {
    var      name: String?
    var isDefault: Bool?
    
    override init() {
        super.init()
    }
}
