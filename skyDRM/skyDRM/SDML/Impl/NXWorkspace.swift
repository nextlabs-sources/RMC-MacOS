//
//  NXWorkspace.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/22/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation
import SDML

protocol NXWorkspaceIF {
    func list(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ())
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ())
    func sync(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ()) -> String
    
    // File operation
    
    func viewFile(file: NXWorkspaceFile, progress: ((Double) -> ())?, completion: @escaping (Error?) -> ()) -> String
    func markFileOffline(file: NXWorkspaceFile, completion: @escaping (Error?) -> ()) -> String
    func unmarkFileOffline(file: NXWorkspaceFile) -> Error?
    func addFile(file: NXFileBase, parent: NXWorkspaceFile?, isLeaveCopy: Bool, progress: ((Double) -> ())?, completion: @escaping (NXWorkspaceFile?, Error?) -> ()) -> String
    func deleteFile(file: NXWorkspaceFile, completion: @escaping (Error?) -> ())
    
    /// Cancel operation.
    func cancel(id: String) -> Bool
}

class NXWorkspace {
    init(workspace: SDMLWorkspaceInterface) {
        self.workspace = workspace
    }
    let workspace: SDMLWorkspaceInterface
    
    static func transformProperty(from: SDMLWorkspaceFile, to: NXWorkspaceFile) {
        NXCommonUtils.transform(from: from, to: to)
        
        to.fileId = from.getFileID()
        to.fileType = from.getFileType()
        to.pathDisplay = from.getPathDisplay()
        to.lastModifiedUser = {
           let userInfo = NXProjectUserInfo()
            NXCommonUtils.transform(from: from.getLastModifier(), to: userInfo)
            return userInfo
        }()
        to.owner = {
            let userInfo = NXProjectUserInfo()
            NXCommonUtils.transform(from: from.getUploader(), to: userInfo)
            return userInfo
        }()
        
        to.isFolder = from.getIsFolder()
        
        let status = NXSyncFileStatus()
        status.type = .download
        status.status = (from.getIsLocation()) ? .completed : .pending
        to.status = status
    }
    
    static func transform(from: SDMLWorkspaceFile, to: NXWorkspaceFile) {
        // Set common property.
        self.transformProperty(from: from, to: to)
        
        guard let children = from.getChildren() else {
            return
        }
        
        var files = [NXWorkspaceFile]()
        for child in children {
            let file = NXWorkspaceFile()
            transform(from: child, to: file)
            file.parent = to
            files.append(file)
        }
        to.subWorkspaceFiles = files
    }
}

extension NXWorkspace: NXWorkspaceIF {
    func list(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ()) {
        workspace.list { (result) in
            guard let value = result.value else {
                completion(nil, result.error!)
                return
            }
            
            var files = [NXWorkspaceFile]()
            for v in value {
                let file = NXWorkspaceFile()
                NXWorkspace.transform(from: v, to: file)
                files.append(file)
            }
            completion(files, nil)
        }
        
    }
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ()) {
        workspace.getStorage { (result) in
            guard let value = result.value else {
                completion(nil, result.error!)
                return
            }
            completion(value, nil)
        }
    }
    
    func sync(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ()) -> String {
        return workspace.sync { (result) in
            guard let value = result.value else {
                completion(nil, result.error!)
                return
            }
            
            var files = [NXWorkspaceFile]()
            for v in value {
                let file = NXWorkspaceFile()
                NXWorkspace.transform(from: v, to: file)
                files.append(file)
            }
            completion(files, nil)
        }
    }
    
    // File operation
    
    func viewFile(file: NXWorkspaceFile, progress: ((Double) -> ())?, completion: @escaping (Error?) -> ()) -> String {
        let workspaceFile = (file.sdmlBaseFile as? SDMLWorkspaceFile)!
        return workspace.viewFile(file: workspaceFile, progress: progress, completion: { (result) in
            if let error = result.error {
                completion(error)
                return
            }
            
            NXWorkspace.transformProperty(from: workspaceFile, to: file)
            completion(nil)
        })
    }
    
    func markFileOffline(file: NXWorkspaceFile, completion: @escaping (Error?) -> ()) -> String {
        let workspaceFile = (file.sdmlBaseFile as? SDMLWorkspaceFile)!
        return workspace.markFileOffline(file: workspaceFile, completion: { (result) in
            if let error = result.error {
                completion(error)
                return
            }
            
            NXWorkspace.transformProperty(from: workspaceFile, to: file)
            completion(nil)
        })
    }
    
    func unmarkFileOffline(file: NXWorkspaceFile) -> Error? {
        let workspaceFile = (file.sdmlBaseFile as? SDMLWorkspaceFile)!
        let result = workspace.unmarkFileOffline(file: workspaceFile)
        if let error = result.error {
            return error
        }
        
        NXWorkspace.transformProperty(from: workspaceFile, to: file)
        return nil
    }
    
    func addFile(file: NXFileBase, parent: NXWorkspaceFile?, isLeaveCopy: Bool, progress: ((Double) -> ())?, completion: @escaping (NXWorkspaceFile?, Error?) -> ()) -> String {
        let outboxFile = (file.sdmlBaseFile as? SDMLOutBoxFile)!
        var parentWorkspaceFile: SDMLWorkspaceFile?
        if let parent = parent {
            parentWorkspaceFile = (parent.sdmlBaseFile as? SDMLWorkspaceFile)!
        }
        return workspace.addFile(file: outboxFile, parent: parentWorkspaceFile, isLeaveCopy: isLeaveCopy, progress: progress, completion: { (result) in
            guard let value = result.value else {
                completion(nil, result.error!)
                return
            }
            
            let file = NXWorkspaceFile()
            NXWorkspace.transform(from: value, to: file)
            file.parent = parent
            completion(file, nil)
        })
    }
    
    func deleteFile(file: NXWorkspaceFile, completion: @escaping (Error?) -> ()) {
        let workspaceFile = (file.sdmlBaseFile as? SDMLWorkspaceFile)!
        workspace.deleteFile(file: workspaceFile) { (result) in
            if let error = result.error {
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    /// Cancel operation.
    func cancel(id: String) -> Bool {
        return workspace.cancel(id: id)
    }
}
