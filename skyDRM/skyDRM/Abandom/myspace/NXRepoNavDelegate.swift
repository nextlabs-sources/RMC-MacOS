//
//  NXRepoNavDelegate.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/6.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

enum RepoNavItem: Int{
    case undefinedRepoNavItem
    case separator
    case allFiles
    case cloudDrive
    case favoriteFiles
    case offlineFiles
    case myVault
    case deleted
    case shared
    case myDrive
}

protocol NXRepoNavDelegate: NSObjectProtocol{
    func navClicked(item: RepoNavItem, userData: Any?)
}
