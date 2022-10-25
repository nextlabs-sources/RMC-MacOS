//
//  NXFileOperationDelegate.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/10.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

enum NXFileOperation:Int {
    case viewProperty
    case downloadFile
    case protectFile
    case shareFile
    case deleteFile
    case logProperty
    case markFavorite
    case printFile
    case viewDetails
    case viewManage
    case openFile
    case doNothing
}

protocol NXFileOperationDelegate: NSObjectProtocol{
    func nxFileOperation(type: NXFileOperation)
}

