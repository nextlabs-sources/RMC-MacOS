//
//  NXFileRenderItem.swift
//  skyDRM
//
//  Created by helpdesk on 4/11/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXFileRenderItem: NSObject {
    var fileItem: NXFileBase?
    var srcType: NXCommonUtils.renderEventSrcType?
    
    var isSteward: Bool?
    
    var isTag: Bool?
    var tags: [String : [String]]?
    
    var rightOb: NXRightObligation?
    var tempFilePath: String?
    var autoDelete: Bool = true

}
