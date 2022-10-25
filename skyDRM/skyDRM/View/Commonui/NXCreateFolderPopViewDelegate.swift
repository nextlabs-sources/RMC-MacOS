//
//  NXCreateFolderPopViewDelegate.swift
//  skyDRM
//
//  Created by xx-huang on 28/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum NXCreateFolderEventType: Int {
    case cancelButtonClicked
    case createButtonClicked
}

protocol  NXCreateFolderPopViewDelegate: NSObjectProtocol{
    func createFolderPopViewFinished(type: NXCreateFolderEventType, newFolderName:String)
}
