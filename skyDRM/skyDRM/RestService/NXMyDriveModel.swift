//
//  NXMyDriveFileItem.swift
//  skyDRM
//
//  Created by pchen on 18/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

struct NXMyDriveFileItem {
    var path: String?
    var pathDisplay: String?
    var size: String?
    var name: String?
    var folder = false
    var lastModified: String?
    
    init(withDictionary dic: Dictionary<String, Any>) {
        if let path = dic["pathId"] as? String {
            self.path = path
        }
        if let pathDisplay = dic["pathDisplay"] as? String {
            self.pathDisplay = pathDisplay
        }
        if let size = dic["size"] as? Int {
            self.size = String(size)
        }
        if let name = dic["name"] as? String {
            self.name = name
        }
        if let folder = dic["folder"] as? Bool {
            self.folder = folder
        }
        if let lastModified = dic["lastModified"] as? Int64 {
            self.lastModified = String(lastModified)
        }
    }
}

struct MyDriveDetailFileItem {
    var filePath: String?
    var fileSize: String?
    var isDirectory: String?
    var success: String?
    
    init(withDictionary dic: [String: Any]) {
        if let filePath = dic["filePath"] as? String {
            self.filePath = filePath
        }
        if let fileSize = dic["fileSize"] as? String {
            self.fileSize = fileSize
        }
        if let isDirectory = dic["isDirectory"] as? Int {
            self.isDirectory = String(isDirectory)
        }
        if let success = dic["success"] as? String {
            self.success = success
        }
    }
}
