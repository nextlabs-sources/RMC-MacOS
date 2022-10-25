//
//  NXAllDrive.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 8/22/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXAllDrive {
    var outbox: NXSynchronizedArray<NXSyncFile>
    var myVault: NXSynchronizedArray<NXSyncFile>
    var shareWithMe: NXSynchronizedArray<NXSyncFile>
    
    /// myVault + outbox(in myvault).
    var myVaultPlus: NXSynchronizedArray<NXSyncFile>!
    
    /// project + outbox(in project).
    var project: NXProjectRoot
    
    /// all offline file in myVault + project + shareWithMe.
    var offline: NXSynchronizedArray<NXSyncFile>!
    
    var workspace: NXWorkspaceCache!
    
    var sharedWorkspace: [NXSharedWorkspaceModel]
    
    init(outbox: [NXSyncFile], myVault: [NXSyncFile], shareWithMe: [NXSyncFile], project: NXProjectRoot,
         workspace: [NXWorkspaceFile], sharedWorkspace: [NXSharedWorkspaceModel]) {
        self.outbox = NXSynchronizedArray(array: outbox)
        self.myVault = NXSynchronizedArray(array: myVault)
        self.shareWithMe = NXSynchronizedArray(array: shareWithMe)
        self.project = project
        self.sharedWorkspace = sharedWorkspace
        self.workspace = NXWorkspaceCache(workspace: workspace, cacheDrive: self)
        
        
        self.restructMixingDriver()
    }
    
    func restructMixingDriver() {
        restructOffline()
        restructMyVaultPlus()
        restructProjectPlus()
    }
    
    func restructMyVaultPlus() {
        var myVaultInOutbox = [NXSyncFile]()
        self.outbox.forEach { (file) in
            if let sdmlOutBoxFile = file.file.sdmlBaseFile as? SDMLOutBoxFile {
                if sdmlOutBoxFile.getOutBoxFileType() == .myVaultFile {
                    myVaultInOutbox.append(file)
                }
            }
        }
        
        myVaultPlus = NXSynchronizedArray(array: myVault.getArray())
        myVaultPlus += myVaultInOutbox
    }
    
    func restructProjectPlus() {
        var projectInOutbox = [NXSyncFile]()
        outbox.forEach { file in
            if let sdmlOutBoxFile = file.file.sdmlBaseFile as? SDMLOutBoxFile {
                if sdmlOutBoxFile.getOutBoxFileType() == .projectFile {
                    projectInOutbox.append(file)
                }
            }
        }
        
        for file in projectInOutbox {
            let localProjectFile = file.file as! NXLocalProjectFileModel
            let searchResult = NXCommonUtils.searchProjectFolder(projectID: (localProjectFile.projectId)!, fileID: (localProjectFile.parentFileId) ?? "", in: project)
            if let folder = searchResult.folder {
                folder.subfiles.append(file)
            } else {
                searchResult.project?.rootFiles.append(file)
            }
        }
    }
    
    func restructProjectPlus(for project: NXProjectModel) {
        var projectInOutbox = [NXSyncFile]()
        outbox.forEach { file in
            if let sdmlOutBoxFile = file.file.sdmlBaseFile as? SDMLOutBoxFile {
                if sdmlOutBoxFile.getOutBoxFileType() == .projectFile {
                    projectInOutbox.append(file)
                }
            }
        }
        
        for file in projectInOutbox {
            let localProjectFile = file.file as! NXLocalProjectFileModel
            if localProjectFile.projectId != project.id {
                continue
            }
            
            let searchResult = NXCommonUtils.searchProjectFolder(projectID: (localProjectFile.projectId)!, fileID: (localProjectFile.parentFileId) ?? "", in: self.project)
            if let folder = searchResult.folder {
                folder.subfiles.append(file)
            } else {
                searchResult.project?.rootFiles.append(file)
            }
        }
    }
    
    func restructOffline() {
        var offlineFiles = [NXSyncFile]()
        myVault.forEach { file in
            if file.file.isOffline {
                offlineFiles.append(file)
            }
        }
        
        shareWithMe.forEach { file in
            if file.file.isOffline {
                offlineFiles.append(file)
            }
        }
        
        for project in project.projects {
            for file in project.rootFiles {
                if file.file.isOffline {
                    offlineFiles.append(file)
                }
            }
            for folder in project.folders {
                let projectFolder = folder.file as! NXProjectFileModel
                offlineFiles += NXCommonUtils.searchOfflineFile(folder: projectFolder)
            }
        }
        
        let files = getWorkspaceOffline()
        let syncFiles = files.map { (file) -> NXSyncFile in
            let syncFile = NXSyncFile(file: file)
            syncFile.syncStatus = file.status
            return syncFile
        }
        offlineFiles.append(contentsOf: syncFiles)
        
        offline = NXSynchronizedArray(array: offlineFiles)
    }

    func getWorkspaceOffline() -> [NXWorkspaceBaseFile] {
        return getWorkspaceOffline(files: workspace.workspace)
    }
    
    private func getWorkspaceOffline(files: [NXWorkspaceBaseFile]) -> [NXWorkspaceBaseFile] {
        var result = [NXWorkspaceBaseFile]()
        for file in files {
            if file.isFolder {
                let offlines = getWorkspaceOffline(files: file.subWorkspaceFiles!)
                result.append(contentsOf: offlines)
            } else {
                if file.isOffline {
                    result.append(file)
                }
            }
        }
        
        return result
    }
}

extension NXAllDrive {
    func addProjectFile(file: NXSyncFile) {
        
        var projectID: Int?
        var parentFileID: String?
        if let localProjectFile = file.file as? NXLocalProjectFileModel {
            projectID = localProjectFile.projectId
            parentFileID = localProjectFile.parentFileId
        } else if let projectFile = file.file as? NXProjectFileModel {
            projectID = projectFile.project?.id
            parentFileID = projectFile.parentFileID
        }
        
        let result = NXCommonUtils.searchProjectFolder(projectID: projectID!, fileID: parentFileID ?? "", in: self.project)
        if let folder = result.folder {
            folder.subfiles.append(file)
        } else {
            result.project?.rootFiles.append(file)
        }
    }
    
    func removeProjectFile(file: NXSyncFile) {
        
        var projectID: Int?
        var parentFileID: String?
        if let localProjectFile = file.file as? NXLocalProjectFileModel {
            projectID = localProjectFile.projectId
            parentFileID = localProjectFile.parentFileId
        } else if let projectFile = file.file as? NXProjectFileModel {
            projectID = projectFile.project?.id
            parentFileID = projectFile.parentFileID
        }
        
        let result = NXCommonUtils.searchProjectFolder(projectID: projectID!, fileID: parentFileID ?? "", in: self.project)
        if let folder = result.folder {
            for (index, projectFile) in folder.subfiles.enumerated() where projectFile.file.getNXLID() == file.file.getNXLID() {
                folder.subfiles.remove(at: index)
                break
            }
        } else if let project = result.project {
            for (index, projectFile) in project.rootFiles.enumerated() where projectFile.file.getNXLID() == file.file.getNXLID() {
                project.rootFiles.remove(at: index)
                break
            }
        }
        
    }
    
    func updateProjectFile(file: NXSyncFile) {
        
        var projectID: Int?
        var parentFileID: String?
        if let localProjectFile = file.file as? NXLocalProjectFileModel {
            projectID = localProjectFile.projectId
            parentFileID = localProjectFile.parentFileId
        } else if let projectFile = file.file as? NXProjectFileModel {
            projectID = projectFile.project?.id
            parentFileID = projectFile.parentFileID
        }
        
        let result = NXCommonUtils.searchProjectFolder(projectID: projectID!, fileID: parentFileID ?? "", in: self.project)
        
        // FIXME: Replace parent and project only for upload.
        (file.file as? NXProjectFileModel)?.project = result.project
        (file.file as? NXProjectFileModel)?.parentFileID = result.folder?.fileId
        
        if let folder = result.folder {
            
            for (index, projectFile) in folder.subfiles.enumerated() where projectFile.file.getNXLID() == file.file.getNXLID() {
                folder.subfiles[index] = file
                break
            }
        } else if let project = result.project {
            for (index, projectFile) in project.rootFiles.enumerated() where projectFile.file.getNXLID() == file.file.getNXLID() {
                project.rootFiles[index] = file
                break
            }
        }
    }
}

// Outbox

extension NXAllDrive {
    
}
