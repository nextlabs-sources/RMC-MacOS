//
//  NXCacheDriver.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 8/15/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

import SDML
import AppKit

enum NXDriverType: CaseIterable {
    case outbox
    case myVault
    case allProject
    case project
    case shareWithMe
    case workspace
    
    case sharedWorkspace
    
}

/// Memory cache for all file.
class NXMemoryDrive {
    
    // Singleton.
    static let sharedInstance = NXMemoryDrive()
    private init() {}
    
    var allDrive: NXAllDrive?
}

// MARK: Get driver.

extension NXMemoryDrive {
    func getOutBox() -> [NXSyncFile] {
        return (self.allDrive?.outbox)!.getArray()
    }
    
    func getOffline() -> [NXSyncFile] {
        return (self.allDrive?.offline)!.getArray()
    }
    
    func getMyVault() -> [NXSyncFile] {
        return (self.allDrive?.myVaultPlus)!.getArray()
    }
    
    func getProject() -> NXProjectRoot {
        return (self.allDrive?.project)!
    }
    
    func getShareWithMe() -> [NXSyncFile] {
        return (self.allDrive?.shareWithMe)!.getArray()
    }
    
    func getWorkspace() -> [NXWorkspaceBaseFile] {
        return self.allDrive!.workspace.workspace
    }
    
}

// MARK: Init and update.

extension NXMemoryDrive {
    /// Init from DB.
    func load(completion: @escaping (Error?) -> ()) {
        
        var outboxResult: [NXSyncFile]?
        var myVaultResult: [NXSyncFile]?
        var projectResult: NXProjectRoot?
        var shareWithMeResult: [NXSyncFile]?
        var workspaceFiles: [NXWorkspaceFile]?
        var sharedWorkspaceResult: [NXSharedWorkspaceModel]?
        
        let group = DispatchGroup()
        for type in NXDriverType.allCases {
            group.enter()
            
            switch type {
            case .outbox:
                fetchOutbox() { (result, error) in
                    outboxResult = result
                    group.leave()
                }
            case .myVault:
                fetchMyVault(fromServer: true) { [weak self] (result, error) in
                    if error != nil {
                        self?.fetchMyVault(fromServer: false) { result, error in
                            myVaultResult = result
                            group.leave()
                        }
                    } else {
                        myVaultResult = result
                        group.leave()
                    }
                    
                    
                }
            case .allProject:
                fetchAllProject(fromServer: true) { [weak self] (result, error) in
                    if error != nil {
                        self?.fetchAllProject(fromServer: false) { result, error in
                            projectResult = result
                            group.leave()
                        }
                    } else {
                        projectResult = result
                        group.leave()
                    }
                    
                }
            case .shareWithMe:
                fetchShareWithMe(fromServer: true) { [weak self] (result, error) in
                    if error != nil {
                        self?.fetchShareWithMe(fromServer: false) { result, error in
                            shareWithMeResult = result
                            group.leave()
                        }
                    } else {
                        shareWithMeResult = result
                        group.leave()
                    }
                    
                }
            case .workspace:
                if NXClientUser.shared.user?.isPersonal == true || AppConfig.isHiddenWorkspace {
                    group.leave()
                } else {
                    let workspace = NXClient.sharedInstance.getWorkspace()!
                    _ = workspace.sync(completion: { (result, error) in
                        if error != nil {
                            workspace.list(completion: { (result, error) in
                                workspaceFiles = result
                                group.leave()
                            })
                        } else {
                            workspaceFiles = result
                            group.leave()
                        }
                    })
                }
            case .sharedWorkspace:
                NXClient.sharedInstance.getSharedWorkspace { result in
                    
                    group.leave()
                    return
                    
                    guard let value = try? result.get() else {
                        group.leave()
                        return
                    }

                    var models = [NXSharedWorkspaceModel]()
                    let syncGroup = DispatchGroup()
                    value.forEach { sharedWorkspace in
                        syncGroup.enter()
                        _ = sharedWorkspace.sync { result in
                            if result.error != nil {
                                syncGroup.leave()
                            }

                            sharedWorkspace.getFiles(parent: nil) { result in
                                guard let files = try? result.get() else {
                                    syncGroup.leave()
                                    return
                                }

                                let model = NXSharedWorkspaceModel(repoInfo: sharedWorkspace.getRepositoryInfo(), rootFiles: files)

                                DispatchQueue.main.async {
                                    models.append(model)
                                    syncGroup.leave()
                                }
                            }

                        }
                    }

                    syncGroup.notify(queue: .global()) {
                        sharedWorkspaceResult = models
                        group.leave()
                    }
                }
            break
                
            default:
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {            
            self.allDrive = NXAllDrive(outbox: outboxResult ?? [], myVault: myVaultResult ?? [], shareWithMe: shareWithMeResult ?? [], project: projectResult ?? NXProjectRoot(), workspace: workspaceFiles ?? [], sharedWorkspace: sharedWorkspaceResult ?? [])
            
            completion(nil)
            return
        }
    }
    
    func unload() {
        self.allDrive = nil
    }
    
    /// Update from server.
    func refresh(type: NXDriverType, project: NXProjectModel? = nil, completion: @escaping (Error?) -> ()) {
        switch type {
        case .myVault:
            fetchMyVault(fromServer: true) { (result, error) in
                if error != nil {
                    completion(error)
                    return
                }
                // FIXME: Not thread safe.
                NXCommonUtils.reserveStatus(old: (self.allDrive?.myVault)!.getArray(), new: result!)
                
                self.allDrive?.myVault = NXSynchronizedArray(array: result!)
                self.allDrive?.restructMyVaultPlus()
                
                completion(nil)
            }
        case .allProject:
            fetchAllProject(fromServer: true) { (result, error) in
                if error != nil {
                    completion(error)
                    return
                }
                
                for project in result!.projects {
                    for oldProject in (self.allDrive?.project)!.projects {
                        if project.id == oldProject.id {
                            NXCommonUtils.reserveStatus(old: oldProject, new: project)
                            break
                        }
                    }
                }
                
                self.allDrive?.project = result!
                self.allDrive?.restructProjectPlus()
                
                completion(nil)
            }
        case .project:
            fetchProject(fromServer: true, project: project!) { (result, error) in
                if error != nil {
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.projectFailed(reason: .invalidProject) = sdmlError {
                        self.updateProject(newProject: project!, isDelete: true)
                        completion(nil)
                        return
                    }
                    completion(error)
                    return
                }
                
                self.updateProject(newProject: result!, isDelete: false)
                completion(nil)
            }
        case .shareWithMe:
            fetchShareWithMe(fromServer: true) { (result, error) in
                if error != nil {
                    completion(error)
                    return
                }
                NXCommonUtils.reserveStatus(old: (self.allDrive?.shareWithMe)!.getArray(), new: result!)
                self.allDrive?.shareWithMe = NXSynchronizedArray(array: result!)
                
                completion(nil)
            }
        case .workspace:
            NXClient.sharedInstance.getWorkspace()?.sync(completion: { (result, error) in
                completion(error)
            })
        default:
            break
        }
    }
}

// MARK: Private methods.

extension NXMemoryDrive {
    private func fetchOutbox(completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        NXClient.getCurrentClient().getFiles(parentPath: "/") { (files, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            
            let syncFiles = files!.map() { file -> NXSyncFile in
                let syncFile = NXSyncFile(file: file)
                syncFile.syncStatus = NXSyncFileStatus()
                return syncFile
            }
            
            completion(syncFiles, nil)
            return
        }
    }
    
    private func fetchMyVault(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        NXClient.getCurrentClient().getFileList(fromServer: fromServer) { (result, error) in
            completion(result, error)
            return
        }
    }
    
    private func fetchAllProject(fromServer: Bool, completion: @escaping (NXProjectRoot?, Error?) -> ()) {
        NXClient.getCurrentClient().getProjects(fromServer: fromServer) { (result, error) in
            completion(result, error)
            return
        }
    }
    
    private func fetchProject(fromServer: Bool, project: NXProjectModel, completion: @escaping (NXProjectModel?, Error?) -> ()) {
        NXClient.getCurrentClient().updateProject(project: project) { (result, error) in
            completion(result, error)
            return
        }
    }
    
    private func fetchShareWithMe(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        NXClient.getCurrentClient().getShareWithMeFileList(fromServer: fromServer) { (result, error) in
            completion(result, error)
            return
        }
    }
    
    private func updateProject(newProject: NXProjectModel, isDelete: Bool) {
        for (index, oldProject) in (self.allDrive?.project)!.projects.enumerated() {
            if newProject.id == oldProject.id {
                if isDelete {
                    self.allDrive?.project.projects.remove(at: index)
                } else {
                    NXCommonUtils.reserveStatus(old: oldProject, new: newProject)
                    self.allDrive?.project.projects[index] = newProject
                    self.allDrive?.restructProjectPlus(for: newProject)
                    self.allDrive?.restructOffline()
                }
                break
            }
        }
        if newProject.ownedByMe == true {
            for (index, oldProject) in (self.allDrive?.project)!.createdByMeProjects.enumerated() {
                if newProject.id == oldProject.id {
                    if isDelete {
                        self.allDrive?.project.createdByMeProjects.remove(at: index)
                    } else {
                        self.allDrive?.project.createdByMeProjects[index] = newProject
                    }
                    break
                }
            }
        } else {
            for (index, oldProject) in (self.allDrive?.project)!.otherCreatedProjects.enumerated() {
                if newProject.id == oldProject.id {
                    if isDelete {
                        self.allDrive?.project.otherCreatedProjects.remove(at: index)
                    } else {
                        self.allDrive?.project.otherCreatedProjects[index] = newProject
                    }
                    break
                }
            }
        }
        
        
    }
}
