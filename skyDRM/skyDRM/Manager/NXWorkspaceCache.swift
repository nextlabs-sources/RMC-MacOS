//
//  NXCacheWorkspace.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/23/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

/// Workspace + Local workspace
class NXWorkspaceCache {
    init(workspace: [NXWorkspaceBaseFile], cacheDrive: NXAllDrive) {
        self.workspace = workspace
        self.cacheDrive = cacheDrive
        
        workspacePlus()
    }
    var workspace: [NXWorkspaceBaseFile]
    weak var cacheDrive: NXAllDrive?
    
}

extension NXWorkspaceCache {
    
    func set(files: [NXWorkspaceBaseFile]) {
        reserveStatus(from: workspace, to: files)
        workspace = files
        
        workspacePlus()
    }
    
    func add(file: NXWorkspaceBaseFile) {
        if let localFile = file as? NXWorkspaceLocalFile {
            if localFile.parentID == nil {
                workspace.append(localFile)
            } else {
                let parent = searchFile(id: localFile.parentID!)
                parent?.subWorkspaceFiles?.append(localFile)
                localFile.parent = parent
            }
        } else {
            
            if let parent = file.parent {
                parent.children?.append(file)
            } else {
                workspace.append(file)
            }
            
        }
        
    }
    
    func remove(file: NXWorkspaceBaseFile) {
        if let localFile = file as? NXWorkspaceLocalFile {
            
            if localFile.parentID == nil {
                for (index, file) in workspace.enumerated() {
                    if file.id == localFile.id {
                        workspace.remove(at: index)
                        break
                    }
                }
            } else {
                let parent = searchFile(id: localFile.parentID!)
                if let children = parent?.subWorkspaceFiles {
                    for (index, file) in children.enumerated() {
                        if file.id == localFile.id {
                            parent?.subWorkspaceFiles?.remove(at: index)
                            break
                        }
                    }
                }
                
                
            }
            
        } else {
            let files: [NXWorkspaceBaseFile]
            if let parent = file.parent as? NXWorkspaceBaseFile {
                files = parent.subWorkspaceFiles!
            } else {
                files = workspace
            }
            
            for (index, f) in files.enumerated() {
                if file.id == f.id {
                    workspace.remove(at: index)
                    break
                }
            }
            
            
        }
    }
    
    func searchFile(id: String) -> NXWorkspaceBaseFile? {
        return searchFile(id: id, files: workspace)
    }
    
    private func searchFile(id: String, files: [NXWorkspaceBaseFile]) -> NXWorkspaceBaseFile? {
        for file in files {
            if file.id == id {
                return file
            }
            
            if let subFiles = file.subWorkspaceFiles,
                let file = searchFile(id: id, files: subFiles) {
                return file
            }
        }
        
        return nil
    }
    
    private func workspacePlus() {
        var files = [NXWorkspaceBaseFile]()
        for file in cacheDrive!.outbox.getArray() {
            if let file = file.file as? NXWorkspaceBaseFile {
                files.append(file)
            }
        }
        for file in files {
            add(file: file)
        }
    }
    
    private func reserveStatus(from: [NXWorkspaceBaseFile], to: [NXWorkspaceBaseFile]) {
        let from = from.filter { (file) -> Bool in
            return file is NXWorkspaceFile
        }
        
        for newFile in to {
            for oldFile in from {
                if oldFile.id == newFile.id {
                    if newFile.isFolder {
                        if let oldChildren = oldFile.subWorkspaceFiles,
                            let newChildren = newFile.subWorkspaceFiles {
                            reserveStatus(from: oldChildren, to: newChildren)
                        }
                        
                    } else {
                        newFile.status = oldFile.status
                    }
                    
                }
            }
        }
    }
}
