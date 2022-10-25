//
//  NXProjectAdapter.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 14/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectAdapterDelegate: NSObjectProtocol{
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
extension NXProjectAdapterDelegate {
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


class NXProjectAdapter: NSObject {
    private var service: NXProjectService?
    weak var delegate: NXProjectAdapterDelegate?
    init(withUserID: String, ticket: String) {
        super.init()
        service = NXProjectService(withUserID: withUserID, ticket: ticket)
        service?.delegate = self
    }
    // MARK: Project Operation
    func listProject(filter: NXListProjectFilter) {
        service?.listProject(filter: filter)
    }
    
    func getProjectMetadata(project: NXProject) {
        service?.getProjectMetadata(project: project)
    }
    
    func createProject(project: NXProject, invitedEmails: [String]?) {
        service?.createProject(project: project, invitedEmails: invitedEmails)
    }
    
    func updateProject(project: NXProject) {
        service?.updateProject(project: project)
    }
    
    func uploadFile(fromFile file: NXProjectFile, toFolder folder: NXProjectFolder, property: NXProjectUploadFileProperty) -> Bool {
        return service?.uploadFile(fromFile: file, toFolder: folder, property: property) ?? false
    }
    
    func listFile(project: NXProject, filter: NXProjectFileFilter) {
        service?.listFile(project: project, filter: filter)
    }
    
    func createFolder(folder: NXProjectFolder, parentFolder: NXProjectFolder, autorename: Bool) {
        service?.createFolder(folder: folder, parentFolder: parentFolder, autorename: autorename)
    }
    
    func deleteFile(file: NXFileBase) {
        service?.deleteFile(file: file)
    }
    
    func getFileMetadata(file: NXProjectFile) {
        service?.getFileMetadata(file: file)
    }
    
    func downlodFile(file: NXProjectFile, toFolder folder: String? = nil, start: Int64? = nil, length: Int64? = nil, forViewer: Bool) -> Bool {
        if forViewer == true,
            let cacheFile = CacheMgr.shared.getCacheFile(with: file),
            cacheFile.localLastModifiedDate == cacheFile.lastModifiedDate as Date,
            FileManager.default.fileExists(atPath: cacheFile.localPath),
            let projectId = file.projectId {
            delegate?.downloadFileFinish(projectId: projectId, from: cacheFile.fullServicePath, to: cacheFile.localPath, file: cacheFile as? NXProjectFile, error: nil, forViewer: forViewer)
            return true
        }
        return service?.downlodFile(file: file, toFolder: folder, start: start, length: length, forViewer: forViewer) ?? false
    }
    
    func cancelDownloadOrUploadFile() {
        service?.cancelDownloadOrUploadFile()
    }
    
    func projectInvitation(project: NXProject, members: [NXProjectMember]) {
        service?.projectInvitation(project: project, members: members)
    }
    
    func sendInvitationReminder(invitation: NXProjectInvitation) {
        service?.sendInvitationReminder(invitation: invitation)
    }
    
    func revokeInvitation(invitation: NXProjectInvitation) {
        service?.revokeInvitation(invitation: invitation)
    }
    
    func acceptInvitation(invitation: NXProjectInvitation) {
        service?.acceptInvitation(invitation: invitation)
    }
    
    func declineInvitation(invitation: NXProjectInvitation, declineReason: String?) {
        service?.declineInvitation(invitation: invitation, declineReason: declineReason)
    }
    
    func listMember(project: NXProject, filter: NXProjectMemberFilter) {
        service?.listMember(project: project, filter: filter)
    }
    
    func removeMember(project: NXProject, member: NXProjectMember) {
        service?.removeMember(project: project, member: member)
    }
    
    func getMemberDetails(project: NXProject, member: NXProjectMember) {
        service?.getMemberDetails(project: project, member: member)
    }
    
    func listPendingInvitationForProject(project: NXProject, filter: NXProjectPendingInvitationFilter) {
        service?.listPendingInvitationForProject(project: project, filter: filter)
    }
    
    func listPendingInvitationForUser() {
        service?.listPendingInvitationForUser()
    }
}

extension NXProjectAdapter: NXProjectServiceDelegate {
    // MARK: Project Operation
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int, projectList: [NXProject]?, error: Error?) {
        let isListAll = {(filter: NXListProjectFilter) -> Bool in
            if filter.listProjectType != .allProject {
                return false
            }
            else {
                if let size = filter.size,
                    size != "" {
                    return false
                }
            }
            return true
        }
        if let error = error {
            var projects: [NXProject]?
            if isListAll(filter) {
                projects = CacheMgr.shared.getProject(with: nil)
            }
            else {
                projects = CacheMgr.shared.getProject(with: filter)
            }
            let totalNumb = CacheMgr.shared.getProjectTotalNumb(with: filter.listProjectType)
            delegate?.listProjectFinish(filter: filter, totalProjects: totalNumb, projectList: projects, error: error)
        }
        else {
            if let projectList = projectList {
                if isListAll(filter) {
                    _ = CacheMgr.shared.syncProject(with: projectList)
                }
                else {
                    _ = CacheMgr.shared.syncProjectPartly(with: projectList)
                }
            }
            delegate?.listProjectFinish(filter: filter, totalProjects: totalProjects, projectList: projectList, error: error)
        }
    }
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?) {
        if let error = error {
            let tmpProject = NXProject()
            tmpProject.projectId = projectId
            let cacheProject = CacheMgr.shared.getCacheProject(with: tmpProject)
            delegate?.getProjectMetadataFinish(projectId: projectId, project: cacheProject, error: error)
        }
        else {
            if let project = project {
                _ = CacheMgr.shared.updateProject(with: project)
            }
            delegate?.getProjectMetadataFinish(projectId: projectId, project: project, error: error)
        }
    }
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        delegate?.createProjectFinish(projectName: projectName, projectId: projectId, error: error)
    }
    func updateProjectFinish(project: NXProject, error: Error?) {
        if error == nil {
            _ = CacheMgr.shared.updateProject(with: project)
        }
        delegate?.updateProjectFinish(project: project, error: error)
    }
    
    // MARK: Project File Operation
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?) {
        delegate?.uploadFileFinish(projectId: projectId, from: from, to: to, error: error)
    }
    func uploadFileProgress(projectId: String, localPath: String, progress: Double) {
        delegate?.uploadFileProgress(projectId: projectId, localPath: localPath, progress: progress)
    }
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXFileBase]?, error: Error?) {
        let isListAllFile = { (filter: NXProjectFileFilter) -> Bool in
            if filter.size != "" {
                return false
            }
            else {
                if let q = filter.qName,
                    q != "" {
                    return false
                }
                if let s = filter.searchString,
                    s != "" {
                    return false
                }
            }
            return true
        }
        if let _ = error {
            var projectfolder: NXProjectFolder?
            if filter.pathId != "/" {
                projectfolder = NXProjectFolder()
                projectfolder?.projectId = projectId
                projectfolder?.fullServicePath = filter.pathId
            }
            let project = NXProject()
            project.projectId = projectId
            
            var files: [NXProjectFileBase]?
            if isListAllFile(filter) {
                files = CacheMgr.shared.getFileUnderFolder(with: project, folder: projectfolder, filter: nil)
            }
            else {
                files = CacheMgr.shared.getFileUnderFolder(with: project, folder: projectfolder, filter: filter)
            }
            delegate?.listFileFinish(projectId: projectId, filter: filter, fileList: files, error: error)
        }
        else {
            if let fileList = fileList as? [NXProjectFileBase] {
                var projectfolder: NXProjectFolder?
                if filter.pathId != "/" {
                    projectfolder = NXProjectFolder()
                    projectfolder?.projectId = projectId
                    projectfolder?.fullServicePath = filter.pathId
                }
                let project = NXProject()
                project.projectId = projectId
                if isListAllFile(filter) {
                    _ = CacheMgr.shared.syncFileUnderFolder(with: project, folder: projectfolder, files: fileList)
                }
                else {
                    _ = CacheMgr.shared.syncFileUnderFolderPartly(with: project, folder: projectfolder, files: fileList)
                }
            }
            delegate?.listFileFinish(projectId: projectId, filter: filter, fileList: fileList, error: error)
        }
    }
    func createFolderFinish(projectId: String, servicePath: String, error: Error?) {
        delegate?.createFolderFinish(projectId: projectId, servicePath: servicePath, error: error)
    }
    func deleteFileFinish(projectId: String, servicePath: String, isFolder: Bool, error: Error?) {
        if error == nil {
            var fileBase: NXProjectFileBase!
            if isFolder {
                let projectFolder = NXProjectFolder()
                fileBase = projectFolder
            }
            else {
                let projectFile = NXProjectFile()
                fileBase = projectFile
            }
            fileBase.projectId = projectId
            fileBase.fullServicePath = servicePath
            _ = CacheMgr.shared.deleteFile(with: fileBase)
        }
        delegate?.deleteFileFinish(projectId: projectId, servicePath: servicePath, isFolder: isFolder, error: error)
    }
    func getFileMetadataFinish(projectId: String, servicePath: String, file: NXProjectFile?, error: Error?) {
        if let error = error {
            let tmpFile = NXProjectFileBase()
            tmpFile.projectId = projectId
            tmpFile.fullServicePath = servicePath
            let cacheFile = CacheMgr.shared.getCacheFile(with: tmpFile) as? NXProjectFile ?? nil
            delegate?.getFileMetadataFinish(projectId: projectId, servicePath: servicePath, file: cacheFile, error: error)
        }
        else {
            if let file = file {
                _ = CacheMgr.shared.updateFile(with: file)
            }
            delegate?.getFileMetadataFinish(projectId: projectId, servicePath: servicePath, file: file, error: error)
        }
    }
    func downloadFileFinish(projectId: String, from: String, to: String, file: NXProjectFile?, error: Error?, forViewer: Bool) {
        if forViewer == true,
            error == nil,
            let file = file {
            if let cacheFile = CacheMgr.shared.getCacheFile(with: file){
                cacheFile.localPath = to
                cacheFile.localLastModifiedDate = cacheFile.lastModifiedDate as Date
                _ = CacheMgr.shared.updateFile(with: cacheFile)
            }
        }
        delegate?.downloadFileFinish(projectId: projectId, from: from, to: to, file: file, error: error, forViewer: forViewer)
    }
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double) {
        delegate?.downloadFileProgress(projectId: projectId, servicePath: servicePath, progress: progress)
    }
    
    func downloadFileSuggestedFileName(projectId: String, servicePath: String, fileName: String, forViewer: Bool) {
        delegate?.downloadFileSuggestedFileName(projectId: projectId, servicePath: servicePath, fileName: fileName, forViewer: forViewer)
    }
    
    // MARK: Project Member Operation
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        delegate?.projectInvitationFinish(projectId: projectId, invitedEmails: invitedEmails, alreadyInvited: alreadyInvited, nowInvited: nowInvited, alreadyMembers: alreadyMembers, error: error)
    }
    func sendInvitationReminderFinish(invitation: NXProjectInvitation, error: Error?) {
        delegate?.sendInvitationReminderFinish(invitation: invitation, error: error)
    }
    func revokeInvitationFinish(invitation: NXProjectInvitation, error: Error?) {
        delegate?.revokeInvitationFinish(invitation: invitation, error: error)
    }
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?) {
        if error == nil {
            _ = CacheMgr.shared.removeInvitationForUser(with: invitation)
        }
        delegate?.acceptInvitationFinish(invitation: invitation, projectId: projectId, error: error)
    }
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?) {
        if error == nil {
            _ = CacheMgr.shared.removeInvitationForUser(with: invitation)
        }
        delegate?.declineInvitationFinish(invitation: invitation, error: error)
    }
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?) {
        let isListAll = { (filter: NXProjectMemberFilter) -> Bool in
            return filter.size == "" && filter.searchString == ""
        }
        if let _ = error {
            var members: [NXProjectMember]?
            let tempProject = NXProject()
            tempProject.projectId = projectId
            if isListAll(filter) {
                members = CacheMgr.shared.getProjectMember(with: tempProject, filter: nil)
            }
            else {
                members = CacheMgr.shared.getProjectMember(with: tempProject, filter: filter)
            }
            delegate?.listMemberFinish(projectId: projectId, filter: filter, memberList: members, error: error)
        }
        else {
            if let memberList = memberList {
                let tempProject = NXProject()
                tempProject.projectId = projectId
                if isListAll(filter) {
                    _ = CacheMgr.shared.syncMember(with: tempProject, members: memberList)
                }
                else {
                    _ = CacheMgr.shared.syncMemberPartly(with: tempProject, members: memberList)
                }
            }
            delegate?.listMemberFinish(projectId: projectId, filter: filter, memberList: memberList, error: error)
        }
    }
    func removeMemberFinish(projectId: String, member: NXProjectMember, error: Error?) {
        if error == nil {
            let tempProject = NXProject()
            tempProject.projectId = projectId
            _ = CacheMgr.shared.removeMember(with: tempProject, member: member)
        }
        delegate?.removeMemberFinish(projectId: projectId, member: member, error: error)
    }
    func getMemberDetailsFinish(projectId: String, member: NXProjectMember?, error: Error?) {
        if let error = error {
            let tempProject = NXProject()
            tempProject.projectId = projectId
            let tempMember = NXProjectMember()
            tempMember.userId = member?.userId
            let cacheMember = CacheMgr.shared.getProjectMemberDetail(with: tempProject, member: tempMember)
            delegate?.getMemberDetailsFinish(projectId: projectId, member: cacheMember, error: error)
        }
        else {
            if let member = member {
                let tempProject = NXProject()
                tempProject.projectId = projectId
                _ = CacheMgr.shared.updateMember(with: tempProject, member: member)
            }
            delegate?.getMemberDetailsFinish(projectId: projectId, member: member, error: error)
        }
    }
    func listPendingInvitationForProjectFinish(projectId: String, filter: NXProjectPendingInvitationFilter, pendingList: [NXProjectInvitation]?, error: Error?) {
        let isListAll = {(filter: NXProjectPendingInvitationFilter) -> Bool in
            return filter.size == "" && filter.searchString == ""
        }
        if let error = error {
            var invitations: [NXProjectInvitation]?
            let tmpProject = NXProject()
            tmpProject.projectId = projectId
            if isListAll(filter) {
                invitations = CacheMgr.shared.getProjectInvitation(with: tmpProject, filter: nil)
            }
            else {
                invitations = CacheMgr.shared.getProjectInvitation(with: tmpProject, filter: filter)
            }
            delegate?.listPendingInvitationForProjectFinish(projectId: projectId, filter: filter, pendingList: invitations, error: error)
        }
        else {
            if let pendingList = pendingList {
                let tmpProject = NXProject()
                tmpProject.projectId = projectId
                if isListAll(filter) {
                    _ = CacheMgr.shared.syncInvitation(with: tmpProject, invitation: pendingList)
                }
                else {
                    _ = CacheMgr.shared.syncInvitationPartly(with: tmpProject, invitation: pendingList)
                }
            }
            delegate?.listPendingInvitationForProjectFinish(projectId: projectId, filter: filter, pendingList: pendingList, error: error)
        }
    }
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?) {
        if let error = error {
            let pendings = CacheMgr.shared.getProjectInvitationForUser()
            delegate?.listPendingInvitationForUserFinish(pendingList: pendings, error: error)
        }
        else {
            if let pendingList = pendingList {
                _ = CacheMgr.shared.syncInvitationForUser(invitation: pendingList)
            }
            delegate?.listPendingInvitationForUserFinish(pendingList: pendingList, error: error)
        }
    }
}
