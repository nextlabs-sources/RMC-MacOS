//
//  NXFileOperationBarDelegate.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/7.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

enum NXFileOperationType: Int {
    case tableView
    case gridView
    case search
    case pathNodeClicked
    case refreshClicked
//    case showHideRepoNav
    case uploadFile
    case downloadFile
    case createFolder
    case selectMenuItem
    case seeViewedBack
    case seeViewedForward
    case changeSharedSegmentValue
}

protocol NXFileOperationBarDelegate: NSObjectProtocol{
    func fileOperationBarDelegate(type: NXFileOperationType, userData: Any?)
}
