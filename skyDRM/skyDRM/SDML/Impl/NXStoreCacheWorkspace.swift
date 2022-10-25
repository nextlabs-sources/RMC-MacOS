//
//  NXCacheWorkspace.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/22/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

class NXStoreCacheWorkspace {
    init(workspace: NXWorkspaceIF) {
        self.workspace = workspace
    }
    
    let workspace: NXWorkspaceIF
}

extension NXStoreCacheWorkspace: NXWorkspaceIF {
    func list(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ()) {
        workspace.list { (value, error) in
            if error == nil {
                NXMemoryDrive.sharedInstance.allDrive?.workspace.set(files: value!)
                NXMemoryDrive.sharedInstance.allDrive?.restructOffline()
            }
            
            completion(value, error)
        }
        
    }
    
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ()) {
        workspace.getStorage(completion: completion)
    }
    
    func sync(completion: @escaping ([NXWorkspaceFile]?, Error?) -> ()) -> String {
        return workspace.sync(completion: { (value, error) in
            if error == nil {
                NXMemoryDrive.sharedInstance.allDrive?.workspace.set(files: value!)
                NXMemoryDrive.sharedInstance.allDrive?.restructOffline()
            }
            
            completion(value, error)
        })
    }
    
    // File operation
    
    func viewFile(file: NXWorkspaceFile, progress: ((Double) -> ())?, completion: @escaping (Error?) -> ()) -> String {
        return workspace.viewFile(file: file, progress: progress, completion: completion)
    }
    
    func markFileOffline(file: NXWorkspaceFile, completion: @escaping (Error?) -> ()) -> String {
        return workspace.markFileOffline(file: file, completion: { (error) in
            if error == nil {
                let syncFile = NXSyncFile(file: file)
                syncFile.syncStatus = file.status
                NXMemoryDrive.sharedInstance.allDrive?.offline.append(syncFile)
            }
            
            completion(error)
        })
    }
    
    func unmarkFileOffline(file: NXWorkspaceFile) -> Error? {
        let error = workspace.unmarkFileOffline(file: file)
        if error == nil {
            for (index, value) in (NXMemoryDrive.sharedInstance.allDrive?.offline)!.enumerated() {
                if value.file.getNXLID() == file.getNXLID() {
                    NXMemoryDrive.sharedInstance.allDrive?.offline.remove(at: index)
                    break
                }
            }
        }
        
        return error
    }
    
    func addFile(file: NXFileBase, parent: NXWorkspaceFile?, isLeaveCopy: Bool, progress: ((Double) -> ())?, completion: @escaping (NXWorkspaceFile?, Error?) -> ()) -> String {
        return workspace.addFile(file: file, parent: parent, isLeaveCopy: isLeaveCopy, progress: progress, completion: { (value, error) in
            if error == nil {
                guard let cacheDrive = NXMemoryDrive.sharedInstance.allDrive else {
                    completion(value, error)
                    return
                }
                
                // Remove file in outbox.
                for (index, f) in cacheDrive.outbox.enumerated() {
                    if file.getNXLID() == f.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.outbox.remove(at: index)
                        break
                    }
                }
                if let localFile = file as? NXWorkspaceBaseFile {
                    NXMemoryDrive.sharedInstance.allDrive?.workspace.remove(file: localFile)
                }
                NXMemoryDrive.sharedInstance.allDrive?.workspace.add(file: value!)
                if value!.isOffline {
                    let syncFile = NXSyncFile(file: value!)
                    syncFile.syncStatus = value!.status
                    NXMemoryDrive.sharedInstance.allDrive?.offline.append(syncFile)
                }
            }
            
            completion(value, error)
        })
    }
    
    func deleteFile(file: NXWorkspaceFile, completion: @escaping (Error?) -> ()) {
        workspace.deleteFile(file: file) { (error) in
            if error == nil {
                NXMemoryDrive.sharedInstance.allDrive?.workspace.remove(file: file)
                if file.isOffline {
                    for (index, f) in NXMemoryDrive.sharedInstance.allDrive!.offline.enumerated() {
                        if let workspaceFile = f.file as? NXWorkspaceFile,
                            workspaceFile.id == file.id {
                            NXMemoryDrive.sharedInstance.allDrive?.offline.remove(at: index)
                            break
                        }
                    }
                }
            }
            
            completion(error)
        }
    }
    
    /// Cancel operation.
    func cancel(id: String) -> Bool {
        return workspace.cancel(id: id)
    }
}
