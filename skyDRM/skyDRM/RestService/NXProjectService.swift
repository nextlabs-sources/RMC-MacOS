//
//  NXProjectService.swift
//  skyDRM
//
//  Created by pchen on 16/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectServiceOperation {
    // MARK: Project Operation
    func listProject(filter: NXListProjectFilter)
    func getProjectMetadata(project: NXProject)
    func createProject(project: NXProject, invitedEmails: [String]?)
    func updateProject(project: NXProject)
    
    // MARK: Project File Operation
    func uploadFile(fromFile file: NXProjectFile, toFolder folder: NXProjectFolder, property: NXProjectUploadFileProperty) -> Bool
    func listFile(project: NXProject, filter: NXProjectFileFilter)
    func createFolder(folder: NXProjectFolder, parentFolder: NXProjectFolder, autorename: Bool)
    func deleteFile(file: NXFileBase)
    func getFileMetadata(file: NXProjectFile)
    func downlodFile(file: NXProjectFile, toFolder folder: String?, start: Int64?, length: Int64?, forViewer: Bool) -> Bool
    
    func cancelDownloadOrUploadFile()
    
    // MARK: Project Member Operation
    func projectInvitation(project: NXProject, members: [NXProjectMember])
    func sendInvitationReminder(invitation: NXProjectInvitation)
    func revokeInvitation(invitation: NXProjectInvitation)
    func acceptInvitation(invitation: NXProjectInvitation)
    func declineInvitation(invitation: NXProjectInvitation, declineReason: String?)
    func listMember(project: NXProject, filter: NXProjectMemberFilter)
    func removeMember(project: NXProject, member: NXProjectMember)
    func getMemberDetails(project: NXProject, member: NXProjectMember)
    func listPendingInvitationForProject(project: NXProject, filter: NXProjectPendingInvitationFilter)
    func listPendingInvitationForUser()
}

protocol NXProjectServiceDelegate:NSObjectProtocol{
    // MARK: Project Operation
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int, projectList: [NXProject]?, error: Error?)
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?)
    func createProjectFinish(projectName: String, projectId: String?, error: Error?)
    func updateProjectFinish(project: NXProject, error: Error?)
    
    // MARK: Project File Operation
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?)
    func uploadFileProgress(projectId: String, localPath: String, progress: Double)
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXFileBase]?, error: Error?)
    func createFolderFinish(projectId: String, servicePath: String, error: Error?)
    func deleteFileFinish(projectId: String, servicePath: String, isFolder: Bool, error: Error?)
    func getFileMetadataFinish(projectId: String, servicePath: String, file: NXProjectFile?, error: Error?)
    func downloadFileFinish(projectId: String, from: String, to: String, file: NXProjectFile?, error: Error?, forViewer: Bool)
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double)
    
    func downloadFileSuggestedFileName(projectId: String, servicePath: String, fileName: String, forViewer: Bool)
    
    // MARK: Project Member Operation
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?)
    func sendInvitationReminderFinish(invitation: NXProjectInvitation, error: Error?)
    func revokeInvitationFinish(invitation: NXProjectInvitation, error: Error?)
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?)
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?)
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?)
    func removeMemberFinish(projectId: String, member: NXProjectMember, error: Error?)
    func getMemberDetailsFinish(projectId: String, member: NXProjectMember?, error: Error?)
    func listPendingInvitationForProjectFinish(projectId: String, filter: NXProjectPendingInvitationFilter, pendingList: [NXProjectInvitation]?, error: Error?)
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?)
}

// optional
extension NXProjectServiceDelegate {
    // MARK: Project Operation
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int, projectList: [NXProject]?, error: Error?) {}
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?) {}
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {}
    func updateProjectFinish(project: NXProject, error: Error?) {}
    
    // MARK: Project File Operation
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?) {}
    func uploadFileProgress(projectId: String, localPath: String, progress: Double) {}
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXFileBase]?, error: Error?) {}
    func createFolderFinish(projectId: String, servicePath: String, error: Error?) {}
    func deleteFileFinish(projectId: String, servicePath: String, isFolder: Bool, error: Error?) {}
    func getFileMetadataFinish(projectId: String, servicePath: String, file: NXProjectFile?, error: Error?) {}
    func downloadFileFinish(projectId: String, from: String, to: String, file: NXProjectFile?, error: Error?, forViewer: Bool) {}
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double) {}
    
    func downloadFileSuggestedFileName(projectId: String, servicePath: String, fileName: String, forViewer: Bool) {}
    
    // MARK: Project Member Operation
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {}
    func sendInvitationReminderFinish(invitation: NXProjectInvitation, error: Error?) {}
    func revokeInvitationFinish(invitation: NXProjectInvitation, error: Error?) {}
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?) {}
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?) {}
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?) {}
    func removeMemberFinish(projectId: String, member: NXProjectMember, error: Error?) {}
    func getMemberDetailsFinish(projectId: String, member: NXProjectMember?, error: Error?) {}
    func listPendingInvitationForProjectFinish(projectId: String, filter: NXProjectPendingInvitationFilter, pendingList: [NXProjectInvitation]?, error: Error?) {}
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?) {}
}

extension NXProjectService: NXProjectServiceOperation {
    // MARK: Project Operation
    func listProject(filter: NXListProjectFilter) {
        
        let completion: NXProjectRestProviderOperation.listProjectCompletion = {
            filter, total, projects, error in
            self.delegate?.listProjectFinish(filter: filter, totalProjects: total, projectList: projects, error: error)
        }
        restProvider.listProject(filter: filter, completion: completion)
    }
    
    func getProjectMetadata(project: NXProject) {
        
        // Input Parameters
        guard let projectId = project.projectId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.getProjectMetadataCompletion = {
            projectId, project, error in
            self.delegate?.getProjectMetadataFinish(projectId: projectId, project: project, error: error)
        }
        restProvider.getProjectMetadata(withProjectId: projectId, completion: completion)
    }
    
    func createProject(project: NXProject, invitedEmails: [String]?) {
        let completion: NXProjectRestProviderOperation.createProjectCompletion = {
            projectName, projectId, error in
            self.delegate?.createProjectFinish(projectName: projectName, projectId: projectId, error: error)
        }
        restProvider.createProject(project: project, invitedEmails: invitedEmails, completion: completion)
    }
    
    func updateProject(project: NXProject) {
        
        let completion: NXProjectRestProviderOperation.updateProjectCompletion = {
            updateProject, error in
            
            if error != nil {
                self.delegate?.updateProjectFinish(project: project, error: error)
            } else {
                self.delegate?.updateProjectFinish(project: updateProject!, error: nil)
            }
        }
        
        restProvider.updateProject(project: project, completion: completion)
    }
    
    func uploadFile(fromFile file: NXProjectFile, toFolder folder: NXProjectFolder, property: NXProjectUploadFileProperty) -> Bool {
        
        // Input Parameters
        guard
            let projectId = folder.projectId
            else { return false }
        
        let name = file.name
        let filePath = file.localPath
        let folderPath = folder.fullServicePath
        
        let progressHandler: NXProjectRestProviderOperation.progressCompletion = {
            progress in
            self.delegate?.uploadFileProgress(projectId: projectId, localPath: filePath, progress: progress)
        }
        
        let completion: NXProjectRestProviderOperation.uploadFileCompletion = {
            projectId, fileName, item, error in
            
            self.delegate?.uploadFileFinish(projectId: projectId, from: filePath, to: item?.pathId, error: error)
        }
        
        self.op = restProvider.uploadFile(projectId: projectId, fileName: name, from: filePath, toFolder: folderPath, property: property, progressHandler: progressHandler, completion: completion)
        return true
    }
    
    func listFile(project: NXProject, filter: NXProjectFileFilter) {
        guard let projectId = project.projectId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.listFileCompletion = {
            projectId, filter, items, error in
            let files: [NXFileBase]? = {
                if let items = items {
                    return items.map() { item -> NXFileBase in
                        var file: NXFileBase
                        if item.isFolder {
                            let folder = NXProjectFolder()
                            folder.projectId = projectId
                            folder.projectName = project.name
                            file = folder
                        } else {
                            let projectFile = NXProjectFile()
                            projectFile.projectId = projectId
                            projectFile.projectName = project.name
                            projectFile.ownerByMe = project.ownedByMe
                            file = projectFile
                        }
                        self.fetchFileInfo(from: item, to: file)
                        return file
                    }
                }
                
                return nil
            }()
            
            
            self.delegate?.listFileFinish(projectId: projectId, filter: filter, fileList: files, error: error)
        }
        restProvider.listFile(projectId: projectId, filter: filter, completion: completion)
    }
    
    func createFolder(folder: NXProjectFolder, parentFolder: NXProjectFolder, autorename: Bool) {
        // Input Parameters
        guard let projectId = parentFolder.projectId  else {
            return
        }
        
        let parentPath = parentFolder.fullServicePath
        
        let completion: NXProjectRestProviderOperation.createFolderCompletion = {
            projectId, folderPath, _, error in
            self.delegate?.createFolderFinish(projectId: projectId, servicePath: folderPath, error: error)
        }
        
        restProvider.createFolder(projectId: projectId, name: folder.name, parentPath: parentPath, autorename: autorename, completion: completion)
    }

    func deleteFile(file: NXFileBase) {

        let completion: NXProjectRestProviderOperation.deleteFileCompletion = {
            projectId, path, error in
            if ((file as? NXProjectFolder) != nil) {
                self.delegate?.deleteFileFinish(projectId: projectId, servicePath: path, isFolder: true, error: error)
            } else {
                self.delegate?.deleteFileFinish(projectId: projectId, servicePath: path, isFolder: false, error: error)
            }
        }
        
        let path = file.fullServicePath
        if let file = file as? NXProjectFile, let projectId = file.projectId {
            restProvider.deleteFile(projectId: projectId, filePath: path, completion: completion)
        }
        else if let file = file as? NXProjectFolder, let projectId = file.projectId {
            restProvider.deleteFile(projectId: projectId, filePath: path, completion: completion)
        }
    }
    
    func getFileMetadata(file: NXProjectFile) {
        guard let projectId = file.projectId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.getFileMetadataCompletion = {
            projectId, path, item, error in
            let file = file
            file.rights = item?.rights
            
            self.delegate?.getFileMetadataFinish(projectId: projectId, servicePath: path, file: file, error: error)
        }
        
        restProvider.getFileMetadata(projectId: projectId, filePath: file.fullServicePath, completion: completion)
    }

    func downlodFile(file: NXProjectFile, toFolder folder: String? = nil, start: Int64? = nil, length: Int64? = nil, forViewer: Bool) -> Bool {
        
        let servicePath = file.fullServicePath
        let fileName = file.name
        guard let projectId = file.projectId else {
            return false
        }
        
        var destinationPath: String
        if let localFolder = folder {
            destinationPath = NXCommonUtils.getDownloadLocalPath(filename: fileName, folderPath: localFolder)!
        } else {
            /// temp cache path
            guard let tempFolder = NXCommonUtils.getTempFolder() else {
                return false
            }
            destinationPath = tempFolder.appendingPathComponent(fileName, isDirectory: false).path
        }
        
        let progressHandler: NXProjectRestProviderOperation.progressCompletion = {
            progress in
            self.delegate?.downloadFileProgress(projectId: projectId, servicePath: servicePath, progress: progress)
        }
        let completion: NXProjectRestProviderOperation.downloadFileCompletion = {
            projectId, from, to, error in
            self.delegate?.downloadFileFinish(projectId: projectId, from: from, to: to, file: file, error: error, forViewer: forViewer)
        }
        
        let fileNameHandler: (String?) -> Void = {
            fileName in
            let name = fileName ?? file.name
            self.delegate?.downloadFileSuggestedFileName(projectId: projectId, servicePath: servicePath, fileName: name, forViewer: forViewer)
        }
        
        self.op = restProvider.downlodFile(projectId: projectId, start: start, length: length, from: servicePath, to: destinationPath, forViewer: forViewer, progressHandler: progressHandler, completion: completion, fileNameHandler: fileNameHandler)
        return true
    }
    
    func cancelDownloadOrUploadFile() {
        if self.op != nil {
            restProvider.cancelDownloadOrUploadFile(op: self.op!)
        }
    }
    
    func projectInvitation(project: NXProject, members: [NXProjectMember]) {
        
        var emails = [String]()
        for member in members {
            if let email = member.email {
                emails.append(email)
            }
        }
        
        let completion: NXProjectRestProviderOperation.projectInvitationCompletion = {
            projectId, emails, alreadyInvited, nowInvited, alreadyMembers, error in
            self.delegate?.projectInvitationFinish(projectId: projectId, invitedEmails: emails, alreadyInvited: alreadyInvited, nowInvited: nowInvited, alreadyMembers: alreadyMembers, error: error)
        }
        
        restProvider.projectInvitation(project: project, emails: emails, completion: completion)
    }
    
    func sendInvitationReminder(invitation: NXProjectInvitation) {
        guard let invitationId = invitation.invitationId else {
            return
        }
        let completion: NXProjectRestProviderOperation.sendInvitationReminderCompletion = {
            _, error in
            self.delegate?.sendInvitationReminderFinish(invitation: invitation, error: error)
        }
        restProvider.sendInvitationReminder(invitationId: invitationId, completion: completion)
    }
    
    func revokeInvitation(invitation: NXProjectInvitation) {
        guard let invitationId = invitation.invitationId else {
            return
        }
        let completion: NXProjectRestProviderOperation.revokeInvitationCompletion = {
            _, error in
            self.delegate?.revokeInvitationFinish(invitation: invitation, error: error)
        }
        restProvider.revokeInvitation(invitationId: invitationId, completion: completion)
    }
    
    func acceptInvitation(invitation: NXProjectInvitation) {
        guard let invitationId = invitation.invitationId, let code = invitation.code else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.acceptInvitationCompletion = {
            _, _, projectId, error in
            self.delegate?.acceptInvitationFinish(invitation: invitation, projectId: projectId, error: error)
        }
        restProvider.acceptInvitation(invitationId: invitationId, code: code, completion: completion)
    }
    
    func declineInvitation(invitation: NXProjectInvitation, declineReason: String?) {
        guard let invitationId = invitation.invitationId, let code = invitation.code else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.declineInvitationCompletion = {
            _, _, error in
            self.delegate?.declineInvitationFinish(invitation: invitation, error: error)
        }
        restProvider.declineInvitation(invitationId: invitationId, code: code, declineReason: declineReason, completion: completion)
    }
    
    func listMember(project: NXProject, filter: NXProjectMemberFilter) {
        guard let projectId = project.projectId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.listMemberCompletion = {
            projectId, filter, members, error in
            self.delegate?.listMemberFinish(projectId: projectId, filter: filter, memberList: members, error: error)
        }
        
        restProvider.listMember(projectId: projectId, filter: filter, completion: completion)
    }

    func removeMember(project: NXProject, member: NXProjectMember) {
        guard let projectId = project.projectId, let memberId = member.userId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.removeMemberCompletion = {
            projectId, _, error in
            self.delegate?.removeMemberFinish(projectId: projectId, member: member, error: error)
        }
        restProvider.removeMember(projectId: projectId, memberId: memberId, completion: completion)
    }

    func getMemberDetails(project: NXProject, member: NXProjectMember) {
        guard let projectId = project.projectId, let memberId = member.userId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.getMemberDetailsCompletion = {
            projectId, memberId, member, error in
            let tmpMember = member ?? NXProjectMember()
            tmpMember.userId = memberId
            self.delegate?.getMemberDetailsFinish(projectId: projectId, member: tmpMember, error: error)
        }
        restProvider.getMemberDetails(projectId: projectId, memberId: memberId, completion: completion)
    }

    func listPendingInvitationForProject(project: NXProject, filter: NXProjectPendingInvitationFilter) {
        guard let projectId = project.projectId else {
            return
        }
        
        let completion: NXProjectRestProviderOperation.listPendingInvitationForProjectCompletion = {
            projectId, _, pendingList, error in
            self.delegate?.listPendingInvitationForProjectFinish(projectId: projectId, filter: filter, pendingList: pendingList, error: error)
        }
        restProvider.listPendingInvitationForProject(projectId: projectId, filter: filter, completion: completion)
    }
    
    func listPendingInvitationForUser() {
        
        let completion: NXProjectRestProviderOperation.listPendingInvitationForUserCompletion = {
            pendingList, error in
            self.delegate?.listPendingInvitationForUserFinish(pendingList: pendingList, error: error)
        }
        restProvider.listPendingInvitationForUser(completion: completion)
    }
}

class NXProjectService {
    init(withUserID userId: String, ticket: String) {
        restProvider = NXProjectRestProvider(withUserID: userId, ticket: ticket)
    }
    
    var restProvider: NXProjectRestProvider!
    
    var op : NXProjectRestOperation?
    
    weak var delegate: NXProjectServiceDelegate?
    
    fileprivate func fetchFileInfo(from item: NXProjectFileItem, to file: NXFileBase) {
        
        if let duid = item.duid {
            file.setNXLID(nxlId: duid)
        }
        if let pathId = item.pathId {
            file.fullServicePath = pathId
        }
        if let pathDisplay = item.pathDisplay {
            file.fullPath = pathDisplay
        }
        if let name = item.name {
            file.name = name
        }
        if let size = item.size {
            file.size = size
        }
        if let lastModified = item.lastModified {
            file.lastModifiedDate = NSDate(timeIntervalSince1970: (Double(lastModified)/1000))
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            file.lastModifiedTime = formatter.string(from: file.lastModifiedDate as Date)
        }
        
        if let file = file as? NXProjectFileBase {
            file.fileId = item.fileId
            file.creationTime = item.creationTime
            file.owner = item.owner
        }
    }
    
    fileprivate func fetchFileInfo(from item: NXProjectFileDetailItem, to file: NXProjectFile) {
        
        if let pathId = item.pathId {
            file.fullServicePath = pathId
        }
        if let pathDisplay = item.pathDisplay {
            file.fullPath = pathDisplay
        }
        if let name = item.name {
            file.name = name
        }
        if let size = item.size {
            file.size = size
        }
        if let lastModified = item.lastModified {
            file.lastModifiedDate = NSDate(timeIntervalSince1970: (Double(lastModified)/1000))
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            file.lastModifiedTime = formatter.string(from: file.lastModifiedDate as Date)
        }
        
        file.rights = item.rights
    }
}
