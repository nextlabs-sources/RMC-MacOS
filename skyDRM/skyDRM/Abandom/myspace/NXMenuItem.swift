//
//  NXMenuItem.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/6.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXMenuItem: NSObject {
    var itemType: RepoNavItem = .undefinedRepoNavItem
    var iconNameSelected:String? = nil
    var iconNameUnselected:String? = nil
    var menuTitle:String = ""
    var userData: Any? = nil
    var subItems = [NXMenuItem]()
}
