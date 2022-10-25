//
//  NXCheckPermissionCenter.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 02/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXCheckPermissionCenter: NSObject {
    
    fileprivate struct Constant {
        static let checkPermissionWindowXibName = "NXCheckPermissionWindowController"
    }
    
    static let sharedInstance = NXCheckPermissionCenter()

    fileprivate var center = [String: NXCheckPermissionWindowController]()
    
    public func checkPermission(from path: String) {
        
        if let windowController = center[path] {
            windowController.showWindow(nil)
            return
        }
        let windowController = NXCheckPermissionWindowController(windowNibName: Constant.checkPermissionWindowXibName)
        windowController.file = fetchFileBase(from: path)
        windowController.delegate = self
        
        windowController.showWindow(nil)
        
        center[path] = windowController
    }
    
    public func checkPermission(with paths: [String]) {
        for path in paths {
            checkPermission(from: path)
        }
    }
}

/// Tool
extension NXCheckPermissionCenter {
    fileprivate func fetchFileBase(from localPath: String) -> NXFileBase {
        let fileBase = NXFile()
        fileBase.localPath = localPath
        fileBase.name = URL(fileURLWithPath: localPath, isDirectory: false).lastPathComponent
        fileBase.fullServicePath = localPath
        fileBase.fullPath = localPath
        
        do{
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: localPath)
            let fileSizeNumber = fileAttributes[FileAttributeKey.size] as! NSNumber
            fileBase.size = fileSizeNumber.int64Value
            if let date = fileAttributes[FileAttributeKey.modificationDate] as? NSDate {
                fileBase.lastModifiedDate = date as NSDate
            }
            
        }catch _ as NSError{
            debugPrint("get local file size failed")
        }
        
        return fileBase
    }
}

extension NXCheckPermissionCenter: NXCheckPermissionWindowControllerDelegate {
    func windowClose(with file: NXFileBase?) {
        if let path = file?.localPath {
            center[path] = nil
        }
        
    }
}
