//
//  NXClient+File.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 8/20/19.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML

// MARK: NXClientDriveOperation

extension NXClientService: NXClientDriveInterface {
    //MARK: -  ------------- outbox ----------
    
    func protectFile(type: NXProtectType, path: String, right: NXRightObligation?, tags: [String : [String]]?, parentFile: SDMLNXLFile?, completion: @escaping (NXNXLFile?, Error?) -> ()) {
        let manager = session.getProtectManager().value
        var sdmlRights: SDMLRightObligation?
        if right != nil {
            NXCommonUtils.transform(from: right!, to: &sdmlRights)
        }
        switch type {
        case .project:
            manager?.protectOriginFile(type: .project, parentFile: parentFile, path: path, rights: sdmlRights, tags: tags, completion: { (result) in
                if let error = result.error {
                    completion(nil, error)
                    return
                }
                let file = NXLocalProjectFileModel()
                let status = NXSyncFileStatus()
                status.status = .waiting
                file.status = status
                file.localFile = true
                NXCommonUtils.transform(from: result.value! as! SDMLOutBoxFile, to: file)
                completion(file, nil)
            })
        case .myVault,
             .myVaultShared:
            manager?.protectOriginFile(type: .myVault, parentFile: nil, path: path, rights: sdmlRights, tags: nil, completion: { (result) in
                if let error = result.error {
                    completion(nil, error)
                    return
                }
                let file = NXNXLFile()
                file.localFile = true
                file.status?.status = .waiting
                NXCommonUtils.transform(from: result.value!, to: file)
                completion(file, nil)
            })
        case .workspace:
            manager?.protectOriginFile(type: .workspace, parentFile: parentFile, path: path, rights: sdmlRights, tags: tags, completion: { (result) in
                guard let sdmlFile = result.value as? SDMLOutBoxFile else {
                    completion(nil, result.error!)
                    return
                }
                let file = NXWorkspaceLocalFile()
                let status = NXSyncFileStatus()
                status.status = .waiting
                file.status = status
                file.localFile = true
                NXCommonUtils.transform(from: sdmlFile, to: file)
                completion(file, nil)
            })
        default:
            // Not support.
            completion(nil, NSError())
        }
    }
    
    func getFiles(parentPath: String, completion: @escaping ([NXNXLFile]?, Error?) -> ()) {
        let manageResult = session.getCacheManager()
        guard let service = manageResult.value else {
            completion(nil, manageResult.error)
            return
        }
        
        service.getFiles() { result in
            guard let sdmlOutBoxFiles = result.value else {
                completion(nil, result.error)
                return
            }
            
            let localFiles = sdmlOutBoxFiles.map { (sdmlFile) -> NXNXLFile in
                if sdmlFile.getOutBoxFileType() == .myVaultFile {
                    let nxlFile = NXNXLFile()
                    NXCommonUtils.transform(from: sdmlFile, to: nxlFile)
                    return nxlFile
                } else if sdmlFile.getOutBoxFileType() == .projectFile {
                    let localProjectFile = NXLocalProjectFileModel()
                    NXCommonUtils.transform(from: sdmlFile, to: localProjectFile)
                    return localProjectFile
                } else if sdmlFile.getOutBoxFileType() == .workspace {
                    let file = NXWorkspaceLocalFile()
                    NXCommonUtils.transform(from: sdmlFile, to: file)
                    return file
                } else {
                    let file = NXNXLFile()
                    return file
                }
            }
            
            completion(localFiles, nil)
            return
        }
        
    }
    
    func deleteFile(file: NXFileBase,isUpload: Bool) -> Error? {
        let manageResult = session.getCacheManager()
        guard let service = manageResult.value else {
            return manageResult.error
        }
        
        let result = service.deleteFile(file: (file.sdmlBaseFile)!, isUpload:isUpload)
        return result.error
        
    }
    
    func decryptFile(file: NXNXLFile, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        let manageResult = session.getCacheManager()
        guard let service = manageResult.value else {
            completion(nil, manageResult.error)
            return
        }
        
        service.decryptFile(file: file.sdmlBaseFile as! SDMLNXLFile, toFolder: toFolder, isOverwrite: isOverwrite) { (result) in
            completion(result.value, result.error)
        }
    }
    
    func reshare(file: NXFileBase, newRecipients: [String], comment: String, completion: @escaping (Error?) -> ()) {
        let manageResult = session.getCacheManager()
        guard let service = manageResult.value else {
            completion(manageResult.error)
            return
        }
        
        service.reshare(file: file.sdmlBaseFile as! SDMLNXLFile, newRecipients: newRecipients, comment: comment) { (result) in
            if result.error == nil {
                if let file = file as? NXNXLFile {
                    file.recipients = newRecipients
                    file.comment = comment
                }
            }
            completion(result.error)
        }
    }
    
    func upload(file: NXFileBase, project: NXProjectModel? = nil, progress: ((Double) -> ())?, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        let manageResult = session.getUploadManager()
        guard let service = manageResult.value else {
            completion(nil, manageResult.error)
            return ""
        }
        
        let isLeaveCopy = NXClientUser.shared.setting.getIsUploadLeaveCopy()
        let id = service.upload(file: file.sdmlBaseFile as! SDMLNXLFile, isLeaveCopy: isLeaveCopy, project: project?.sdmlProject, progress: progress) { (result) in
            if let error = result.error {
                completion(nil, error)
                return
            }
            
            if let sdmlProjectFile = result.value as? SDMLProjectFile {
                let projectFile = NXProjectFileModel()
                NXCommonUtils.transform(from: sdmlProjectFile, to: projectFile)
                
                let mockProject = NXProjectModel()
                mockProject.id = sdmlProjectFile.getProjectId()
                projectFile.project = mockProject
                
                if let parentFile = sdmlProjectFile.getParentFile() {
                    let mockParentFile = NXProjectFileModel()
                    mockParentFile.fullServicePath = parentFile.getPathID()
                    mockParentFile.fileId = parentFile.getFileId()
                    projectFile.parentFileID = mockParentFile.fileId
                }
                
                completion(projectFile, nil)
                return
            } else if let sdmlMyVaultFile = result.value as? SDMLMyVaultFile {
                let myVaultFile = NXMyVaultFile()
                NXCommonUtils.transform(from: sdmlMyVaultFile, to: myVaultFile)
                completion(myVaultFile, nil)
                return
            } else if let _ = result.value as? SDMLOutBoxFile {
                completion(file, nil)
                return
            } else {
                completion(nil, NSError())
                return
            }
            
        }
        
        return id
    }
    
    func cancel(id: String) -> Bool {
        let manageResult = session.getUploadManager()
        guard let service = manageResult.value else {
            return false
        }
        
        return service.cancel(id: id)
    }
    
    //MARK: -  ------------- myVault ----------
    // /var/folders/gr/npsntphn7qj3t8s53cbdmzqjz2pv6q/T/com.nxrmc.skyDRM/nextlabs/rmc
    func getFileList(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        let managerResult = session.getMyVaultManager()
        
        guard let service = managerResult.value else {
            completion(nil, managerResult.error)
            return
        }
        service.getFiles("/", fromServer, false) { (result) in
            
            guard let libFiles = result.value else {
                completion(nil, result.error)
                return
            }
            
            let files = libFiles.filter({ (item) -> Bool in
                return !item.getIsDeleted() && !item.getIsRevoked()
            }).map { (libFile) -> NXMyVaultFile in
                let file = NXMyVaultFile()
                NXCommonUtils.transform(from: libFile, to: file)
                return file
            }
            let fileList = files.map() { file -> NXSyncFile in
                let syncFile = NXSyncFile(file: file)
                let status = NXSyncFileStatus()
                status.status = file.isLocation==true ?.completed :.pending
                status.type = .download
                syncFile.syncStatus = status
                return syncFile
            }
            
            completion(fileList, nil)
        }
    }
    
    func makeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        file.syncStatus?.status = .syncing
        let manage = session.getMyVaultManager()
        guard let service = manage.value else {
            completion(nil, manage.error)
            return
        }
        _ = service.makeFileOffline(file.file.sdmlBaseFile as! SDMLMyVaultFile , completion: { (result) in
            guard let dbFile = result.value else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                
                file.syncStatus?.status = .failed
                completion(file, result.error)
                return
            }
            let nxmyValut = NXMyVaultFile()
            NXCommonUtils.transform(from: dbFile as! SDMLMyVaultFile, to: nxmyValut)
            file.syncStatus?.status = .completed
            file.file = nxmyValut
            file.file.isOffline = true
            completion(file, nil)
        })
    }
    
    func makeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        let manage = session.getMyVaultManager()
        guard let service = manage.value else {
            completion(nil, manage.error)
            return
        }
        
        let result = service.makeFileUnoffline(file: file.file.sdmlBaseFile as! SDMLMyVaultFile)
        guard let dbFile = result.value else {
            completion(nil, result.error)
            return
        }
        
        let nxmyValut = NXMyVaultFile()
        NXCommonUtils.transform(from: dbFile as! SDMLMyVaultFile, to: nxmyValut)
        file.syncStatus?.status = .pending
        file.file = nxmyValut
        file.file.isOffline = false
        completion(file, nil)
    }
    
    func viewMyVaultFileOnline(file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String {
        let manage = session.getMyVaultManager()
        guard let service = manage.value else {
            completion(nil,manage.error)
            return ""
        }
        return service.viewFileOnline(file:file.sdmlBaseFile as! SDMLMyVaultFile, progress: nil) { (result) in
            guard let dbFile = result.value as? SDMLMyVaultFile else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                completion(nil,result.error)
                return
            }
            NXCommonUtils.transform(from: dbFile, to: file as! NXMyVaultFile)
            file.sdmlBaseFile = dbFile
            completion(file,nil)
        }
    }
    
    func remoteViewRepo(file:NXFileBase,repoId:String?,completion: @escaping (SDMLRemoteViewResult?, Error?) -> ())
    {
        let result = session.getRemoteViewManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        
        if let repoID = repoId {
            _ = manager.viewRepo(repoId:repoID,file:file.sdmlBaseFile as! SDMLNXLFile, progress: nil) { (result) in
                completion(result.value, result.error)
            }
        }else{
            NXClient.getCurrentClient().getMyVaultRepoDetail(){(result, error) in
                guard let repoId = result?.getRepoID()  else {
                    completion(nil, error)
                    return
                }
                NXCommonUtils.saveLocalDriveRepoId(repoId:repoId)
                _ = manager.viewRepo(repoId:repoId,file:file.sdmlBaseFile as! SDMLNXLFile, progress: nil) { (result) in
                    completion(result.value, result.error)
                }
            }
        }
    }
    
    // MARK:- --------------ShareWithMe-----------------
    func getShareWithMeFileList(fromServer:Bool, completion:@escaping([NXSyncFile]?,Error?)->()) {
        let managerResult = session.getShareWithMeManager()
        guard let service = managerResult.value else {
            completion(nil,managerResult.error)
            return
        }
        service.getFiles("/", fromServer, isLocation: false) { (result) in
            
            guard let libFiles = result.value else {
                completion(nil,result.error)
                return
            }
            
            let files = libFiles.map { (libFile) -> NXShareWithMeFile in
                let file = NXShareWithMeFile()
                NXCommonUtils.transform(from: libFile, to: file)
                return file
            }
            
            let fileList = files.map() { file -> NXSyncFile in
                let syncFile = NXSyncFile(file: file)
                let status = NXSyncFileStatus()
                status.status = file.isLocation==true ?.completed:.pending
                status.type = .download
                syncFile.syncStatus = status
                return syncFile
            }
            completion(fileList, nil)
            
        }
    }
    
    func sharedMakeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        file.syncStatus?.status = .syncing
        let manage = session.getShareWithMeManager()
        guard let service = manage.value else {
            completion(nil, manage.error)
            return
        }
        
        _ = service.makeFileOffline(file.file.sdmlBaseFile as! SDMLShareWithMeFile, completion: { (result) in
            guard let dbFile = result.value else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                file.syncStatus?.status = .failed
                completion(file, result.error)
                return
            }
            let nxShared = NXShareWithMeFile()
            NXCommonUtils.transform(from: dbFile as! SDMLShareWithMeFile, to: nxShared)
            file.syncStatus?.status = .completed
            file.file = nxShared
            completion(file, nil)
        })
    }
    
    func sharedMakeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        let manage = session.getShareWithMeManager()
        guard let service = manage.value else {
            completion(nil, manage.error)
            return
        }
        
        let result = service.makeFileUnoffline(file.file.sdmlBaseFile as! SDMLShareWithMeFile)
        guard let dbFile = result.value else {
            completion(nil, result.error)
            return
        }
        let nxmyValut = NXShareWithMeFile()
        NXCommonUtils.transform(from: dbFile as! SDMLShareWithMeFile, to: nxmyValut)
        file.syncStatus?.status = .pending
        file.file = nxmyValut
        completion(file, nil)
    }
    
    func viewShareWithMeFileOnline( file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String {
        let manager = session.getShareWithMeManager()
        guard let service = manager.value else {
            completion(nil,manager.error)
            return ""
        }
        return service.viewFileOnline(file:file.sdmlBaseFile as! SDMLShareWithMeFile, progress: nil) { (result) in
            guard let dbFile = result.value as? SDMLShareWithMeFile else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                completion(nil,result.error)
                return
            }
            NXCommonUtils.transform(from: dbFile, to: file as! NXShareWithMeFile)
            file.sdmlBaseFile = dbFile
            completion(file,nil)
        }
    }
    
    // MARK:- --------------project-----------------
    func getProjects( fromServer: Bool, completion: @escaping (NXProjectRoot?, Error?) -> ()) -> () {
        self.flage = true
        let manager = session.getProjectManager()
        guard let service = manager.value else {
            completion(nil,manager.error)
            return
        }
        let projectRoot = NXProjectRoot()
        service.getProjectList(fromServer) { (result) in
            guard let libProject = result.value else {
                completion(projectRoot,result.error)
                self.flage = false
                return
            }
            
            
            let projects = libProject.map { (libProject) -> NXProjectModel in
                let project = NXProjectModel()
                NXCommonUtils.transform(from: libProject , to: project, isUpdate: false)
                return project
            }
            
            var byMeProjects = [NXProjectModel]()
            var otherProjects = [NXProjectModel]()
            for project in projects {
                if project.ownedByMe == true {
                    byMeProjects.append(project)
                } else {
                    otherProjects.append(project)
                }
            }
            
            // Sort project: byMe + other
            byMeProjects.sort { $0.name.lowercased() < $1.name.lowercased() }
            otherProjects.sort { $0.name.lowercased() < $1.name.lowercased() }
            
            projectRoot.createdByMeProjects = byMeProjects
            projectRoot.otherCreatedProjects = otherProjects
            projectRoot.projects = byMeProjects + otherProjects
            
            DispatchQueue.main.async {
                self.flage = false
                completion(projectRoot, nil)
                return
            }
        }
    }
    
    func updateProject(project: NXProjectModel, completion: @escaping(NXProjectModel?,Error?) -> ()) -> () {
        let manager = (session.getProjectManager().value)!
        manager.getProjectMetaData(project: project.sdmlProject!) { (result) in
            project.sdmlProject?.getFileManager().update(completion: { (result) in
                guard let newProject = result.value else {
                    completion(nil,result.error)
                    return
                }
                let nxProject = NXProjectModel()
                NXCommonUtils.transform(from: newProject, to: nxProject, isUpdate: true)
                DispatchQueue.main.async {
                    completion(nxProject,nil)
                    return
                }
            })
        }
        
    }
    
    func getRightObligationWithTags(totalProject: SDMLProject?, isWorkspace: Bool, tags:[String:[String]],completion: @escaping(NXRightObligation?,Error?)->()) ->(){
        if isWorkspace {
            let workspace = session.getWorkspace().value!
            workspace.evaluate(tags: tags) { result in
                guard let rightOblightion = result.value else {
                    completion(nil, result.error)
                    return
                }
                let rightObligation = NXRightObligation()
                NXCommonUtils.transform(from: rightOblightion, to: rightObligation)
                completion(rightObligation, nil)
            }
            return
        }
        
        let manager = session.getProjectManager()
        guard  let service = manager.value else {
            completion(nil,manager.error)
            return
        }
        service.getNXLFileObligation(totalProject: totalProject, tags: tags) { result in
            guard let rightOblightion = result.value else {
                completion(nil,result.error)
                return
            }
            let rightObligation = NXRightObligation()
            NXCommonUtils.transform(from: rightOblightion, to: rightObligation)
            completion(rightObligation,nil)
        }
    }
    
    func addNXLFileToProject(file: NXNXLFile?, goalProject: SDMLNXLFile, systemFilePath:String?, tags: [String:[String]], completion: @escaping(NXNXLFile?, Error?) -> ()) -> () {
        guard let sdmlProjectFile = goalProject as? SDMLProjectFile else {
            completion(nil, "get sdmlProjectFile faild" as? Error)
            return
        }
        
        if let _ = goalProject as? SDMLProjectFile {
            sdmlProjectFile.getProject().getFileManager().addNXLFileToProject(file: file != nil ? (file?.sdmlBaseFile as? SDMLNXLFile) : nil, tags: tags, systemFilePath: systemFilePath, goalProject: goalProject, completion: { (result) in
                guard let sdmlFile = result.value else {
                    completion(nil, result.error!)
                    return
                }
                let nxFile = NXLocalProjectFileModel()
                NXCommonUtils.transform(from: sdmlFile as! SDMLOutBoxFile, to: nxFile)
                completion(nxFile, nil)
            })
        }
    }
    
    func makeFileOfflineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        file.syncStatus?.status = .syncing
        guard let sdmlProjectFile = file.file.sdmlBaseFile as? SDMLProjectFile else {
            completion(nil, "get sdmlProjectFile faild" as? Error)
            return
        }
        sdmlProjectFile.getProject().getFileManager().makeFileOffline(file.file.sdmlBaseFile as? SDMLProjectFile , completion: { (result) in
            guard let dbFile = result.value else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                file.syncStatus?.status = .failed
                completion(file, result.error)
                return
            }
            
            let nxProjectFile = NXProjectFileModel()
            NXCommonUtils.transform(from: dbFile as! SDMLProjectFile, to: nxProjectFile)
            file.syncStatus?.status = .completed
            let nxProject = ((file.file as? NXProjectFileModel)?.project)!
            NXCommonUtils.transform(from: sdmlProjectFile.getProject(), to: nxProject, isUpdate: true)
            nxProjectFile.project = nxProject
            file.file = nxProjectFile
            file.file.isOffline = true
            completion(file, nil)
        })
    }
    
    
    func makeFileOnlineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        guard let sdmlProjectFile = file.file.sdmlBaseFile as? SDMLProjectFile else {
            completion(nil, "get sdmlProjectFile faild" as? Error)
            return
        }
        let result = sdmlProjectFile.getProject().getFileManager().makeFileUnoffline(file: file.file.sdmlBaseFile as! SDMLProjectFile)
        guard let dbFile = result.value else {
            completion(nil, result.error)
            return
        }
        let nxmyValut = NXProjectFileModel()
        NXCommonUtils.transform(from: dbFile as! SDMLProjectFile, to: nxmyValut)
        let nxProject = ((file.file as? NXProjectFileModel)?.project)!
        NXCommonUtils.transform(from: sdmlProjectFile.getProject(), to: nxProject, isUpdate: true)
        nxmyValut.project = nxProject
        file.syncStatus?.status = .pending
        file.file = nxmyValut
        file.file.isOffline = false
        completion(file, nil)
    }
    
    func viewFileOnlineOfProject(file: NXFileBase,completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        guard let sdmlProjectFile = file.sdmlBaseFile as? SDMLProjectFile else {
            completion(nil, "get sdmlProjectFile faild" as? Error)
            return ""
        }
        
        return sdmlProjectFile.getProject().getFileManager().viewFileOnline(file:file.sdmlBaseFile as! SDMLProjectFile, progress: nil) { (result) in
            guard let dbFile = result.value as? SDMLProjectFile else {
                if let sdmlError = result.error,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    return
                }
                completion(nil,result.error)
                return
            }
            NXCommonUtils.transform(from: dbFile, to: file as! NXProjectFileModel)
            file.sdmlBaseFile = dbFile
            completion(file,nil)
        }
    }
    
    func remoteViewProject(projectID:String,file:NXFileBase, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ())
    {
        let result = session.getRemoteViewManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        
        _ = manager.viewProject(projectID:projectID, file:file.sdmlBaseFile as! SDMLNXLFile, progress:nil){ (result) in
            completion(result.value, result.error)
        }
    }
    
    // MARK: - Workspace
    
    
    // MARK:- --------------Common-----------------
    
    static func getObligationForViewInfo(file:NXSyncFile, completion:@escaping(NXSyncFile?,Error?)->()) {
        
        guard let nxlFile = file.file.sdmlBaseFile as? SDMLNXLFile else {
            completion(nil,"TransformFaild" as? Error)
            return
        }
        nxlFile.getOnlineRightObligation { (result) in
            guard let sdmlObligation = result.value else {
                completion(file,result.error)
                return
            }
            DispatchQueue.main.async {
                let obligation = NXRightObligation()
                NXCommonUtils.transform(from: sdmlObligation!, to: obligation)
                if let nxNXFile = file.file as? NXNXLFile {
                    nxNXFile.rights = obligation.rights
                    nxNXFile.watermark = obligation.watermark
                    nxNXFile.expiry = obligation.expiry
                    nxNXFile.isTagFile = nxlFile.isTagFile()
                    nxNXFile.tags      = nxlFile.getTag()
                    nxNXFile.isOwner   = nxlFile.getIsOwner()
                }
                completion(file,nil)
            }
        }
    }
    
    func viewFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        guard let nxlFile = file.sdmlBaseFile as? SDMLNXLFile else {
            completion(nil,"TransformFaild" as? Error)
            return ""
        }
        if nxlFile is SDMLShareWithMeFile {
            return self.viewShareWithMeFileOnline(file: file) { (file, error) in
                guard let file = file else {
                    completion(nil,error)
                    return
                }
                completion(file,nil)
            }
        } else if nxlFile is SDMLMyVaultFile {
            
            if(file.localFile == false &&  NXFileRenderSupportUtil.renderFileType(fileName: file.name) == NXFileContentType.REMOTEVIEW){
                completion(file,nil)
                return ""
            }
            
            let myvaultFile = nxlFile as! SDMLMyVaultFile
            if myvaultFile.getIsDeleted() == true{
                 let userInfo = [NSLocalizedDescriptionKey: "FILE_OPERATION_FILE_DELETED_FROM_MYVAULT".localized]
                let error = NSError(domain: NX_ERROR_RENDER_FILE, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NXFILE_DELETED.rawValue, userInfo: userInfo)
                  completion(nil,error)
                return ""
            }
            
            return self.viewMyVaultFileOnline(file: file) { (file, error) in
                guard let file = file else {
                    completion(nil,error)
                    return
                }
                completion(file,nil)
            }
        } else if nxlFile is SDMLProjectFile {
            
            if(file.localFile == false &&  NXFileRenderSupportUtil.renderFileType(fileName: file.name) == NXFileContentType.REMOTEVIEW){
                completion(file,nil)
                return ""
            }
            
            return self.viewFileOnlineOfProject(file: file) { (file, error) in
                guard let file = file else {
                    completion(nil,error)
                    return
                }
                completion(file,nil)
            }
        } else if let workspaceFile = file as? NXWorkspaceFile {
            return self.getWorkspace()!.viewFile(file: workspaceFile, progress: nil, completion: { (error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                completion(file, nil)
            })
        }
        
        return ""
    }
    
    func cancelDownload(id: String) -> Bool {
        guard let downloadManager = session.getDownloadManager().value else {
            return false
        }
        
        return downloadManager.cancel(id: id)
    }
    
    func getWorkspace() -> NXWorkspaceIF? {
        if let workspace = session.getWorkspace().value {
            return NXWorkspace(workspace: workspace)
        }
        
        return nil
    }
}
