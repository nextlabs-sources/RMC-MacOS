//
//  CacheMgr.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/16.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class CacheMgr {
    static let shared = CacheMgr()
    
    private init(){}
    func addAndUpdateBoundService(userId: String, repository: NXRMCRepoItem) -> Bool {
        if DBBoundServiceHandler.shared.getBoundServiceByAccount(userId: userId, account: repository.accountName, type: repository.type) == nil
        {
            let bs = NXBoundService()
            bs.repoId = repository.repoId
            bs.serviceAccount = repository.accountName
            bs.serviceType = repository.type.rawValue
            bs.serviceAccountId = repository.accountId
            bs.serviceAlias = repository.name
            bs.serviceAccountToken = repository.token
            bs.userId = userId
            bs.serviceIsSelected = false
            bs.serviceIsAuthed = true
            return DBBoundServiceHandler.shared.addNewBoundService(item: bs)
        }
        return updateBoundService(userId: userId, repository: repository)
    }
    func addNewBoundService(bs: NXBoundService)->Bool
    {
        if let service = ServiceType(rawValue: bs.serviceType),
            DBBoundServiceHandler.shared.getBoundServiceByAccount(userId: bs.userId, account: bs.serviceAccount, type: service) == nil
        {
            return DBBoundServiceHandler.shared.addNewBoundService(item: bs)
        }
        return false
        
    }
    func updateBoundService(userId: String, repository: NXRMCRepoItem) -> Bool {
        let boundServices = DBBoundServiceHandler.shared.getAllBoundServiceWithUserId(userId: userId)
        for boundService in boundServices {
            if boundService.repoId == repository.repoId,
                boundService.serviceType == repository.type.rawValue,
                boundService.serviceAccount == repository.accountName {
                boundService.serviceAccountId = repository.accountId
                boundService.serviceAlias = repository.name
                boundService.serviceIsAuthed = repository.isAuth
                return DBBoundServiceHandler.shared.updateBoundService(item: boundService)
            }
        }
        return false
    }
    func saveBoundService(userId: String, repositories: [NXRMCRepoItem], beforeDelBoundService: ((NXBoundService) -> Void)? = nil) -> Bool {
        return syncBoundService(userId: userId, repositories: repositories, beforeDelBoundService: beforeDelBoundService)
    }
    func deleteBoundService(userId: String, repository: NXRMCRepoItem) -> Bool {
        let boundServices = DBBoundServiceHandler.shared.getAllBoundServiceWithUserId(userId: userId)
        for boundService in boundServices {
            if boundService.repoId == repository.repoId,
                boundService.serviceType == repository.type.rawValue,
                boundService.serviceAccount == repository.accountName {
                return deleteBoundService(bs: boundService)
            }
        }
        return false
    }
    func deleteBoundService(bs: NXBoundService) -> Bool {
        deleteFilesUnderRoot(bs: bs)
        return DBBoundServiceHandler.shared.deleteBoundService(item: bs)
    }
    
    private func deleteFilesUnderFolder(folder: NXFileBase) {
        let subfiles = DBFileBaseHandler.shared.getSubFiles(fileBase: folder)
        for file in subfiles {
            if file is NXFolder {
                deleteFilesUnderFolder(folder: file)
            }
            else {
                _ = DBFileBaseHandler.shared.deleteTargetFileNode(fileBase: file)
            }
        }
        _ = DBFileBaseHandler.shared.deleteTargetFileNode(fileBase: folder)
    }
    private func deleteFilesUnderRoot(bs: NXBoundService) {
        let root = NXFileBase()
        getFilesUnderRoot(bs: bs, root: root)
        guard let files = root.getChildren() as! [NXFileBase]? else {
            return
        }
        for file in files {
            if file is NXFolder {
                deleteFilesUnderFolder(folder: file)
            }
            else {
                _ = DBFileBaseHandler.shared.deleteTargetFileNode(fileBase: file)
            }
        }
    }
    func getAllBoundService() -> [(boundService: NXBoundService, root: NXFileBase)] {
        let boundServices = DBBoundServiceHandler.shared.getAllBoundService()
        
        var allBoundServices:[(boundService: NXBoundService, root: NXFileBase)] = []
        for bs in boundServices
        {
            let root:NXFileBase = NXFolder()
            root.isRoot = true
            root.boundService = bs
            root.fullPath = "/"
            root.fullServicePath = "/"
            
            let tmp = (bs, root)
            
            allBoundServices.append(tmp)
        }
        
        return allBoundServices
    }
    func getAllBoundService(userId: String) ->[(boundService: NXBoundService, root: NXFileBase)]
    {
        let boundServices = DBBoundServiceHandler.shared.getAllBoundServiceWithUserId(userId: userId);
        
        var allBoundServices:[(boundService: NXBoundService, root: NXFileBase)] = []
        for bs in boundServices
        {
            let root:NXFileBase = NXFolder()
            root.isRoot = true
            root.boundService = bs
            root.fullPath = "/"
            root.fullServicePath = "/"
            
            let tmp = (bs, root)
            
            allBoundServices.append(tmp)
        }
        
        return allBoundServices
    }
    
    func saveFilesUnderRoot(bs: NXBoundService, files: NSArray?) -> Bool
    {
        guard let files = files as? [NXFileBase] else {
            return false
        }
        // TODO: only use to save myvault to coredata now, extend in future
        if bs.serviceType == ServiceType.kServiceMyVault.rawValue {
            return syncFileSystem(isRoot: true, bs: bs, folder: nil, files: files)
        }
        
        let needAddSet = NSMutableSet(array: files)
        return syncData(isRoot: true, bs: bs, folder: nil, needAddSet: needAddSet)
    }
    
    func saveMyVaultFiles(bs: NXBoundService, files: [NXFileBase], isSharedWithMe: Bool) -> Bool {
        if isSharedWithMe {
            if let files = files as? [NXSharedWithMeFile] {
                return DBSharedWithMeFileHandler.shared.updateAll(with: files)
            }
        } else {
            if let files = files as? [NXNXLFile] {
                return DBMyVaultFileHandler.shared.updateAll(withBoundService: bs, files: files)
            }
        }
        
        return true
    }
    
    func getFilesUnderRoot(bs: NXBoundService, root: NXFileBase)
    {
        let files: [NXFileBase] = {
            // TODO: only use to save myvault to coredata now, extend in future
            if bs.serviceType == ServiceType.kServiceMyVault.rawValue {
                return DBMyVaultFileHandler.shared.getAll()
            } else {
                return DBFileBaseHandler.shared.getRootWithBoundService(boundService: bs)
            }
        }()
        
        root.removeAllChildren()
        for tmp in files
        {
            root.addChild(child: tmp)
        }
        
    }
    
    func saveFilesUnderFolder(folder: NXFileBase, files: NSArray?) -> Bool {
        if (folder as? NXFolder) == nil || files == nil{
            Swift.print("parent nxfilebase should be a folder object")
            return false
        }
        
        let fileSet = NSMutableSet(array: files as! [Any])
        
        return self.syncData(isRoot: false, bs: nil, folder: folder, needAddSet: fileSet)
    }
    
    func getFilesUnderFolder(folder: NXFileBase)
    {
        folder.removeAllChildren()
        
        let files = DBFileBaseHandler.shared.getSubFiles(fileBase: folder)
        
        for tmp in files{
            folder.addChild(child: tmp)
        }
        
    }
    
    // private functions
    private func syncBoundService(userId: String, repositories: [NXRMCRepoItem], beforeDelBoundService: ((NXBoundService) -> Void)?) -> Bool {
        let boundServices = DBBoundServiceHandler.shared.getAllBoundServiceWithUserId(userId: userId);
        var needDelSet = [NXBoundService]()
        var needUpdateSet = [NXBoundService]()
        
        ///////////////////////////////////////////////////////////////////////////
        // Add mydrive & myvault if they're not exist
        func addMyVault(with repoId: String) -> Bool {
            let myVault = NXBoundService()
            myVault.repoId = repoId
            myVault.serviceAlias = "MyVault"
            myVault.serviceIsAuthed = true
            myVault.serviceType = ServiceType.kServiceMyVault.rawValue
            myVault.userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
            
            return self.addNewBoundService(bs: myVault)
        }
        
        func addMyDrive(with item: NXRMCRepoItem) -> Bool {
            let myDrive = item.correspondNXBoundService()
            myDrive.serviceIsAuthed = true
            return self.addNewBoundService(bs: myDrive)
        }
        
        let myDrives = repositories.filter() { $0.type == .kServiceSkyDrmBox }
        if let myDrive = myDrives.first {
            _ = addMyDrive(with: myDrive)
            _ = addMyVault(with: myDrive.repoId)
        }
        ///////////////////////////////////////////////////////////////////////////
        
        for boundService in boundServices {
            var bFound = false
            
            for repository in repositories{
                if repository.type.rawValue == boundService.serviceType {
                    let normalRop: [ServiceType] = [.kServiceGoogleDrive, .kServiceDropbox, .kServiceOneDrive, .kServiceSharepointOnline]
                    if normalRop.contains(repository.type) {
                        if repository.repoId == boundService.repoId {
                            bFound = true
                            boundService.serviceAccountId = repository.accountId
                            boundService.serviceAccount = repository.accountName
                            boundService.serviceAlias = repository.name
                            break
                        }
                    }
                    else if repository.type == .kServiceSkyDrmBox{
                        bFound = true
                        
                        boundService.repoId = repository.repoId
                        boundService.serviceAccountId = repository.accountId
                        boundService.serviceAccount = repository.accountName
                        boundService.serviceAccountToken = repository.token
                        boundService.serviceAlias = repository.name
                        break
                    }
                }
            }
            
            // myVault update repoId same as mydrive
            if boundService.serviceType == ServiceType.kServiceMyVault.rawValue {
                bFound = true
                let myDrives = repositories.filter() { $0.type == .kServiceSkyDrmBox }
                if let repoId = myDrives.first?.repoId {
                    boundService.repoId = repoId
                }
            }
            
            if bFound == true {
                needUpdateSet.append(boundService)
            }
            else {
                needDelSet.append(boundService)
            }
        }
        //MARK: fixme considering repository added by another device
        for item in needUpdateSet {
            if false == DBBoundServiceHandler.shared.updateBoundService(item: item) {
                Swift.print("failed to update bound service ")
                return false
            }
        }
        for item in needDelSet {
            if beforeDelBoundService != nil {
                beforeDelBoundService!(item)
            }
            if false == DBBoundServiceHandler.shared.deleteBoundService(item: item) {
                Swift.print("failed to delete bound service ")
                return false
            }
        }
        return true
    }
    
    private func syncFileSystem(isRoot: Bool, bs: NXBoundService?, folder:NXFolder?, files: [NXFileBase]) -> Bool {
        if isRoot {
            guard let bs = bs else {
                return false
            }
            
            if let files = files as? [NXNXLFile] {
                return DBMyVaultFileHandler.shared.updateAll(withBoundService: bs, files: files)
            } else if let files = files as? [NXSharedWithMeFile] {
                return DBSharedWithMeFileHandler.shared.updateAll(with: files)
                // TODO: normal file update
            }
        } else {
            // TODO: normal file update under folder
        }
        
        return true
    }
    
    private func syncData(isRoot: Bool, bs:NXBoundService?, folder:NXFileBase?, needAddSet: NSMutableSet)->Bool
    {
        var needDelSet:[NXFileBase] = []
        var needUpdateSet:[NXFileBase] = []
        
        var files: [NXFileBase]? = nil
        if isRoot{
            files = DBFileBaseHandler.shared.getRootWithBoundService(boundService: bs!)
        }else{
            files = DBFileBaseHandler.shared.getSubFiles(fileBase: folder!)
        }
        
        
        
        for old in files!{
            var found = false
            for tmp in needAddSet{
                let newFile = tmp as! NXFileBase
                if old.fullServicePath == newFile.fullServicePath{
                    found = true
                    
                    old.lastModifiedTime = newFile.lastModifiedTime
                    old.lastModifiedDate = newFile.lastModifiedDate
                    old.size = newFile.size
                    old.refreshDate = newFile.refreshDate
                    old.isRoot = newFile.isRoot
                    old.name = newFile.name
                    old.serviceAlias = newFile.serviceAlias
                    old.isOffline = newFile.isOffline
                    old.isFavorite = newFile.isFavorite
                    
                    old.fullPath = newFile.fullPath
                    
                    needAddSet.remove(tmp)
                    
                    break
                }
            }
            
            if found == false{
                // need delete
                needDelSet.append(old)
            }else
            {
                // need update
                needUpdateSet.append(old)
            }
            
        }
        
        if isRoot{
            if (!DBFileBaseHandler.shared.addFiles2BoundService(boundService: bs!, fileBaseSet: needAddSet)){
                Swift.print("addFiles2BoundService")
                return false
            }
        }else{
            if (!DBFileBaseHandler.shared.addFiles2TargetNode(fileBaseSet: needAddSet, targetNode: folder!)){
                Swift.print("addFiles2TargetNode failed")
                return false
            }
        }
        
        
        for tmp in needDelSet{
            if (!DBFileBaseHandler.shared.deleteTargetFileNode(fileBase: tmp)){
                Swift.print("deleteTargetFilenode failed")
                return false
            }
            
        }
        
        for tmp in needUpdateSet{
            if (!DBFileBaseHandler.shared.updateFileNode(fileBase: tmp))
            {
                Swift.print("updateFileNode failed")
                return false
            }
        }
        
        return true
    }
    
    func syncSkyDrmFavorite(with files: [NXFavFileItem]) -> Bool {
        let mydrives = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceSkyDrmBox)
        if let mydrive = mydrives.first {
            let mydriveItem = files.filter() { $0.fromMyVault == false }
            _ = DBFileBaseHandler.shared.updateAllFavorite(service: mydrive, files: mydriveItem)
        }
        
        let myvaults = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceMyVault)
        if let myvault = myvaults.first {
            let myvaultItem = files.filter() { $0.fromMyVault == true }
            _ = DBFileBaseHandler.shared.updateAllFavorite(service: myvault, files: myvaultItem)
        }
        
        return true
    }
    
    func getSkyDrmFavorite() -> [NXFileBase] {
        var mydriveFavFile: [NXFileBase]?
        let mydrives = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceSkyDrmBox)
        if let mydrive = mydrives.first {
            mydriveFavFile = DBFileBaseHandler.shared.getFavoriteFile(in: mydrive)
        }
        
        var myvaultFavFile: [NXFileBase]?
        let myvaults = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceMyVault)
        if let myvault = myvaults.first {
            myvaultFavFile = DBFileBaseHandler.shared.getFavoriteFile(in: myvault)
        }
        
        var result = [NXFileBase]()
        if let favFile = mydriveFavFile {
            result.append(contentsOf: favFile)
        }
        if let favFile = myvaultFavFile {
            result.append(contentsOf: favFile)
        }
        return result
    }
    
    func updateFavOrOffline(isFav: Bool, files: [NXFileBase]) -> Bool {
        return DBFileBaseHandler.shared.updateFavOrOfflineInFileNode(isFav: isFav, fileBases: files)
    }
    
    func getFavOrOffline(isFav: Bool, bsArray: [NXBoundService]) -> [NXFileBase]
    {
        return DBFileBaseHandler.shared.getAllFavOrOffline(isFav: isFav, bsArray: bsArray)
    }
    
    func updateFileNode(node: NXFileBase)->Bool
    {
        return DBFileBaseHandler.shared.updateFileNode(fileBase: node)
    }
}

// Project Cache
extension CacheMgr {
    ////////////////////////////////////////////////////////////////////////////
    // Project
    // Get
    
    /// get project from core data.
    /// - Parameter filter: get all project if *filter* is `nil`.
    func getProject(with filter: NXListProjectFilter?) -> [NXProject]? {
        if filter == nil {
            return DBProjectHandler.shared.getAllProject(with: true)
        } else {
            return DBProjectHandler.shared.getActiveProject(with: filter!)
        }
    }
    
    /// get project information from core data.
    /// - Parameter project: *projectId* needed.
    func getCacheProject(with project: NXProject) -> NXProject? {
        return DBProjectHandler.shared.getProjectDetail(with: project)
    }
    
    func getProjectTotalNumb(with type: NXListProjectType) -> Int {
        return DBProjectHandler.shared.getProjectTotalNumb(with: type)
    }
    
    // Set
    func syncProject(with projects: [NXProject]) -> Bool {
        return DBProjectHandler.shared.syncProject(with: projects, isWithDelete: true, isActive: true)
    }
    
    func syncProjectPartly(with projects: [NXProject]) -> Bool {
        return DBProjectHandler.shared.syncProject(with: projects, isWithDelete: false, isActive: true)
    }
    
    func createProject(with project: NXProject) -> Bool {
        return DBProjectHandler.shared.createProject(with: project)
    }
    
    func updateProject(with project: NXProject) -> Bool {
        return DBProjectHandler.shared.updateProject(with: project)
    }
    
    ////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////
    // ProjectFile
    // Get
    // TODO: filter
    /**
     - Parameters:
        - project: projectId needed.
        - folder: get root files if *folder* is `nil`.
        - filter: get all file under *folder* if *filter* is `nil`.
    */
    func getFileUnderFolder(with project: NXProject, folder: NXProjectFolder?, filter: NXProjectFileFilter?) -> [NXProjectFileBase]? {
        return DBProjectFileBaseHandler.shared.getFileUnderFolder(with: project, nxFolder: folder, filter: filter)
    }
    
    /// - Parameter file: projectId and fullServicePath needed.
    func getCacheFile(with file: NXProjectFileBase) -> NXProjectFileBase? {
        return DBProjectFileBaseHandler.shared.getFileDetail(with: file)
    }
    
    // Set
    /**
     add and update files.
     - Parameters:
        - project: projectId needed.
        - folder: get root files if *folder* is `nil`.
        - files: *fullServicePath* needed.
     */
    func syncFileUnderFolderPartly(with project: NXProject, folder: NXProjectFolder?, files: [NXProjectFileBase]) -> Bool {
        
        return DBProjectFileBaseHandler.shared.syncFileUnderFolder(with: project, folder: folder, files: files, isWithDelete: false)
    }
    
    /**
     add, update and delete files.
     - Parameters:
        - project: projectId needed.
        - folder: get root files if *folder* is `nil`.
        - files: *fullServicePath* needed.
     */
    func syncFileUnderFolder(with project: NXProject, folder: NXProjectFolder?, files: [NXProjectFileBase]) -> Bool {
        
        return DBProjectFileBaseHandler.shared.syncFileUnderFolder(with: project, folder: folder, files: files, isWithDelete: true)
    }
    
    /**
     add file.
     - Parameters:
        - project: projectId needed.
        - folder: get root files if *folder* is `nil`.
        - file: *fullServicePath* needed.
     */
    func createFileUnderFolder(with project: NXProject, folder: NXProjectFolder?, file: NXProjectFileBase) -> Bool {
        
        return DBProjectFileBaseHandler.shared.addFileUnderFolder(with: project, folder: folder, file: file)
    }
    
    /// delete file.
    /// - Parameter file: projectId and fullServicePath needed.
    func deleteFile(with file: NXProjectFileBase) -> Bool {
        return DBProjectFileBaseHandler.shared.deleteFile(with: file)
    }
    
    /// update file.
    /// - Parameter file: projectId and fullServicePath needed.
    func updateFile(with file: NXProjectFileBase) -> Bool {
        return DBProjectFileBaseHandler.shared.updateFile(with: file)
    }
    ////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////
    // ProjectMember
    /**
     - Parameters:
        - project: projectId needed.
        - filter: get all member in project if *filter* is `nil`.
     */
    func getProjectMember(with project: NXProject, filter: NXProjectMemberFilter?) -> [NXProjectMember]? {
        return DBProjectMemberHandler.shared.getProjectMember(with: project, filter: filter)
    }
    
    /**
     - Parameters:
        - project: projectId needed.
        - member: userId needed.
     */
    func getProjectMemberDetail(with project: NXProject, member: NXProjectMember) -> NXProjectMember? {
        return DBProjectMemberHandler.shared.getProjectMemberDetail(with: project, member: member)
    }
    
    // Set
    /**
     add, update and delete member.
     - Parameters:
        - project: projectId needed.
        - members: userId needed.
     */
    func syncMember(with project: NXProject, members: [NXProjectMember]) -> Bool {
        return DBProjectMemberHandler.shared.syncMember(with: project, members: members, isWithDelete: true)
    }
    
    /**
     add and update member.
     - Parameters:
        - project: projectId needed.
        - members: userId needed.
     */
    func syncMemberPartly(with project: NXProject, members: [NXProjectMember]) -> Bool {
        return DBProjectMemberHandler.shared.syncMember(with: project, members: members, isWithDelete: true)
    }
    
    /**
     remove member.
     - Parameters:
        - project: projectId needed.
        - member: userId needed.
     */
    func removeMember(with project: NXProject, member: NXProjectMember) -> Bool {
        return DBProjectMemberHandler.shared.removeMember(with: project, member: member)
    }
    
    /**
     update member.
     - Parameters:
        - project: projectId needed.
        - member: userId needed.
     */
    func updateMember(with project: NXProject, member: NXProjectMember) -> Bool {
        return false
    }
    ////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////
    // ProjectInvitation
    /**
     - Parameters:
        - project: projectId needed.
        - filter: get all invitation in project if *filter* is `nil`.
     */
    func getProjectInvitation(with project: NXProject, filter: NXProjectPendingInvitationFilter?) -> [NXProjectInvitation]? {
        return DBProjectInvitationHandler.shared.getActiveProjectInvitation(with: project, filter: filter)
    }
    
    /// get all invitation for current user.
    func getProjectInvitationForUser() -> [NXProjectInvitation]? {
        return DBProjectInvitationHandler.shared.getProjectInvitationForUser()
    }
    
    // Set
    /**
     add, update and delete invitation.
     - Parameters:
        - project: projectId needed.
        - invitation: invitationId needed.
     */
    func syncInvitation(with project: NXProject, invitation: [NXProjectInvitation]) -> Bool {
        return DBProjectInvitationHandler.shared.syncActiveInvitation(with: project, invitation: invitation, isWithDelete: true)
    }
    
    /// add, update and delete invitation for user.
    /// - Parameter invitation: invitationId and project needed.
    func syncInvitationForUser(invitation: [NXProjectInvitation]) -> Bool {
        return DBProjectInvitationHandler.shared.syncInvitationForUser(invitation: invitation)
    }
    
    /**
     add and update invitation.
     - Parameters:
        - project: projectId needed.
        - invitation: invitationId needed.
     */
    func syncInvitationPartly(with project: NXProject, invitation: [NXProjectInvitation]) -> Bool {
        return DBProjectInvitationHandler.shared.syncActiveInvitation(with: project, invitation: invitation, isWithDelete: false)
    }
    
    /// remove invitation for user.
    /// - Parameter invitation: invitationId and project needed.
    func removeInvitationForUser(with invitation: NXProjectInvitation) -> Bool {
        return DBProjectInvitationHandler.shared.removeInvitationForUser(with: invitation)
    }
    ////////////////////////////////////////////////////////////////////////////
}
