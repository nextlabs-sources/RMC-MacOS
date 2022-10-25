//
//  NXClientAdapter.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 8/19/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML

/// NXClient + NXMemoryDriver
class NXClientCacheDrive {
    init(drive: NXClientDriveInterface) {
        self.client = drive
    }
    let client: NXClientDriveInterface
    
}

extension NXClientCacheDrive: NXClientDriveInterface {
    
    // MARK: Outbox
    func protectFile(type: NXProtectType, path: String, right: NXRightObligation?, tags: [String : [String]]?, parentFile: SDMLNXLFile?, completion: @escaping (NXNXLFile?, Error?) -> ()) {
        client.protectFile(type: type, path: path, right: right, tags: tags, parentFile: parentFile) { file, error in
            if let file = file {
                
                let syncFile = NXSyncFile(file: file)
                let status = NXSyncFileStatus()
                syncFile.syncStatus = status
                
                NXMemoryDrive.sharedInstance.allDrive?.outbox.append(syncFile)
                if type == .myVault || type == .myVaultShared {
                    NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus.append(syncFile)
                } else if type == .project {
                    NXMemoryDrive.sharedInstance.allDrive?.addProjectFile(file: syncFile)
                } else if type == .workspace {
                    NXMemoryDrive.sharedInstance.allDrive?.workspace.add(file: file as! NXWorkspaceLocalFile)
                }
            }
            
            completion(file, error)
            return
        }
    }
    
    func getFiles(parentPath: String, completion: @escaping ([NXNXLFile]?, Error?) -> ()) {
        client.getFiles(parentPath: parentPath, completion: completion)
    }
    
    func deleteFile(file: NXFileBase, isUpload: Bool) -> Error? {
        let result = client.deleteFile(file: file, isUpload: isUpload)
        if result == nil && isUpload == false {
            
            for (index, f) in (NXMemoryDrive.sharedInstance.allDrive?.outbox)!.enumerated() {
                if file.getNXLID() == f.file.getNXLID() {
                    NXMemoryDrive.sharedInstance.allDrive?.outbox.remove(at: index)
                    break
                }
            }
            if file is NXLocalProjectFileModel {
                NXMemoryDrive.sharedInstance.allDrive?.removeProjectFile(file: NXSyncFile(file: file))
            } else if let file = file as? NXWorkspaceLocalFile {
                NXMemoryDrive.sharedInstance.allDrive?.workspace.remove(file: file)
            } else {
                for (index, f) in (NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus)!.enumerated() {
                    if file.getNXLID() == f.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus.remove(at: index)
                        break
                    }
                }
            }
            
        }
        
        return result
    }
    
    func decryptFile(file: NXNXLFile, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        client.decryptFile(file: file, toFolder: toFolder, isOverwrite: isOverwrite, completion: completion)
    }
    
    func reshare(file: NXFileBase, newRecipients: [String], comment: String, completion: @escaping (Error?) -> ()) {
        client.reshare(file: file, newRecipients: newRecipients, comment: comment, completion: completion)
    }
    
    func upload(file: NXFileBase, project: NXProjectModel? = nil, progress: ((Double) -> ())?, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        
        var targetProject: NXProjectModel?
        if let localProjectFile = file as? NXLocalProjectFileModel {
            for project in (NXMemoryDrive.sharedInstance.allDrive?.project.projects)! {
                if project.id == localProjectFile.projectId {
                    targetProject = project
                    break
                }
            }
        }
        
        let uploadID = client.upload(file: file, project: targetProject, progress: progress) { file, error in
            if let file = file {
                // Remove file in outbox.
                guard let cacheDrive = NXMemoryDrive.sharedInstance.allDrive else {
                    return
                }
                
                for (index, f) in cacheDrive.outbox.enumerated() {
                    if file.getNXLID() == f.file.getNXLID() {
                        cacheDrive.outbox.remove(at: index)
                        break
                    }
                }
                
                // Add file in myvault or project.
                let syncFile = NXSyncFile(file: file)
                let status = NXSyncFileStatus()
                status.status = file.isOffline == true ? .completed : .pending
                status.type = .download
                syncFile.syncStatus = status
                
                if file is NXMyVaultFile {
                    // Insert or do nothing.
                    let memoryFile = cacheDrive.myVault.first(where: { (syncFile) -> Bool in
                        if syncFile.file.getNXLID() == file.getNXLID() {
                            return true
                        }
                        
                        return false
                    })
                    
                    if memoryFile == nil {
                        cacheDrive.myVault.append(syncFile)
                        for (index, f) in cacheDrive.myVaultPlus.enumerated() {
                            if file.getNXLID() == f.file.getNXLID() {
                                cacheDrive.myVaultPlus[index] = syncFile
                                break
                            }
                        }
                    }
                    
                } else if file is NXProjectFileModel {
                    cacheDrive.updateProjectFile(file: syncFile)
                
                } else {
                    // Remove file in outbox for upload twice.
                    for (index, f) in cacheDrive.myVaultPlus.enumerated() {
                        if file.getNXLID() == f.file.getNXLID() {
                            cacheDrive.myVaultPlus.remove(at: index)
                            break
                        }
                    }
                }
                
                let isLeaveCopy = NXClientUser.shared.setting.getIsUploadLeaveCopy()
                if isLeaveCopy {
                    cacheDrive.offline.append(syncFile)
                }
            }
            
            
            
            completion(file, error)
            return
        }
        return uploadID
    }
    
    func cancel(id: String) -> Bool {
        return client.cancel(id: id)
    }
    
    // MARK: MyVault
    
    func getFileList(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        client.getFileList(fromServer: fromServer, completion: completion)
    }
    
    func makeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.makeFileOffline(file: file) { result, error in
            if error == nil, let result = result {
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.myVault)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.myVault[index] = result
                        break
                    }
                }
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus[index] = result
                        break
                    }
                }
                NXMemoryDrive.sharedInstance.allDrive?.offline.append(result)
            }
            
            completion(file, error)
        }
    }
    
    func makeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.makeFileOnline(file: file) { result, error in
            if error == nil, let result = result {
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.myVault)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.myVault[index] = result
                        break
                    }
                }
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.myVaultPlus[index] = result
                        break
                    }
                }
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.offline)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.offline.remove(at: index)
                        break
                    }
                }
            }
            
            completion(file, error)
        }
    }
    
    func viewMyVaultFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return client.viewMyVaultFileOnline(file: file, completion: completion)
    }
    
    func remoteViewRepo(file: NXFileBase, repoId: String?, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        client.remoteViewRepo(file: file, repoId: repoId, completion: completion)
    }
    
    // MARK: ShareWithMe
    
    func getShareWithMeFileList(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        client.getShareWithMeFileList(fromServer: fromServer, completion: completion)
    }
    
    func sharedMakeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.sharedMakeFileOffline(file: file) { result, error in
            if error == nil, let result = result {
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.shareWithMe)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.shareWithMe[index] = result
                        break
                    }
                }
                NXMemoryDrive.sharedInstance.allDrive?.offline.append(result)
            }
            
            completion(result, error)
        }
    }
    
    func sharedMakeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.sharedMakeFileOnline(file: file) { result, error in
            if error == nil, let result = result {
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.shareWithMe)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.shareWithMe[index] = result
                        break
                    }
                }
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.offline)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.offline.remove(at: index)
                        break
                    }
                }
            }
            
            completion(result, error)
        }
    }
    
    func viewShareWithMeFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return client.viewShareWithMeFileOnline(file: file, completion: completion)
    }
    
    // MARK: Project
    
    func getProjects(fromServer: Bool, completion: @escaping (NXProjectRoot?, Error?) -> ()) {
        client.getProjects(fromServer: fromServer, completion: completion)
    }
    
    func getRightObligationWithTags(totalProject: SDMLProject?, isWorkspace: Bool, tags: [String : [String]], completion: @escaping (NXRightObligation?, Error?) -> ()) {
        client.getRightObligationWithTags(totalProject: totalProject, isWorkspace: isWorkspace, tags: tags, completion: completion)
    }
    
    func addNXLFileToProject(file: NXNXLFile?, goalProject: SDMLNXLFile, systemFilePath: String?, tags: [String : [String]], completion: @escaping (NXNXLFile?, Error?) -> ()) {
        client.addNXLFileToProject(file: file, goalProject: goalProject, systemFilePath: systemFilePath, tags: tags) { result, error in
            if let result = result {

                let newFile = result as! NXLocalProjectFileModel
                
                let syncFile = NXSyncFile(file: newFile)
                syncFile.syncStatus = NXSyncFileStatus()
                
                NXMemoryDrive.sharedInstance.allDrive?.addProjectFile(file: syncFile)
                NXMemoryDrive.sharedInstance.allDrive?.outbox.append(syncFile)
            }
            
            completion(result, error)
        }
    }
    
    func viewFileOnlineOfProject(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return client.viewFileOnlineOfProject(file: file, completion: completion)
    }
    
    func updateProject(project: NXProjectModel, completion: @escaping (NXProjectModel?, Error?) -> ()) {
        client.updateProject(project: project, completion: completion)
    }
    
    func makeFileOfflineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.makeFileOfflineOfProject(file: file) { result, error in
            if error == nil, let result = result {
//                let projectFile = file.file as! NXProjectFileModel
//                if let parent = projectFile.parentFile {
//                    for (index, file) in parent.subfiles.enumerated() {
//                        if file.file.getNXLID() == result.file.getNXLID() {
//
//                            parent.subfiles[index] = result
//                            break
//                        }
//                    }
//                }
                NXMemoryDrive.sharedInstance.allDrive?.offline.append(result)
            }
            
            completion(result, error)
        }
    }
    
    func makeFileOnlineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        client.makeFileOnlineOfProject(file: file) { result, error in
            if error == nil, let result = result {
                //let projectFile = file.file as! NXProjectFileModel
//                if let parent = projectFile.parentFile {
//                    for (index, file) in parent.subfiles.enumerated() {
//                        if file.file.getNXLID() == result.file.getNXLID() {
//
//                            parent.subfiles[index] = result
//                            break
//                        }
//                    }
//                }
                for (index, file) in (NXMemoryDrive.sharedInstance.allDrive?.offline)!.enumerated() {
                    if file.file.getNXLID() == result.file.getNXLID() {
                        NXMemoryDrive.sharedInstance.allDrive?.offline.remove(at: index)
                        break
                    }
                }
                
            }
            
            completion(result, error)
            
        }
    }
    
    func remoteViewProject(projectID: String, file: NXFileBase, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        client.remoteViewProject(projectID: projectID, file: file, completion: completion)
    }
    
    func cancelDownload(id: String) -> Bool {
        return client.cancelDownload(id: id)
    }
    
    func getWorkspace() -> NXWorkspaceIF? {
        if let workspace = client.getWorkspace() {
            return NXStoreCacheWorkspace(workspace: workspace)
        }
        
        return nil
    }
    
    // MARK: Common
    
    static func getObligationForViewInfo(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) {
        NXClientService.getObligationForViewInfo(file: file, completion: completion)
    }
    
    func viewFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return client.viewFileOnline(file: file, completion: completion)
    }
}
