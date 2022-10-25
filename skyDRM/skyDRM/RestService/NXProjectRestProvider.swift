//
//  NXProjectService.swift
//  skyDRM
//
//  Created by pchen on 14/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectRestProviderOperation {
// MARK: Project Operation
    func listProject(filter: NXListProjectFilter, completion: @escaping listProjectCompletion)
    func getProjectMetadata(withProjectId projectId: String, completion: @escaping getProjectMetadataCompletion)
    func createProject(project: NXProject, invitedEmails: [String]?, completion: @escaping createProjectCompletion)
    func updateProject(project: NXProject, completion: @escaping updateProjectCompletion)
    
// MARK: Project File Operation
    func uploadFile(projectId: String, fileName: String, from: String, toFolder: String, property: NXProjectUploadFileProperty, progressHandler: @escaping progressCompletion, completion: @escaping uploadFileCompletion) -> NXProjectRestOperation?
    func listFile(projectId: String, filter: NXProjectFileFilter, completion: @escaping listFileCompletion)
    func createFolder(projectId: String, name: String, parentPath path: String, autorename: Bool, completion: @escaping createFolderCompletion)
    func deleteFile(projectId: String, filePath path: String, completion: @escaping deleteFileCompletion)
    func getFileMetadata(projectId: String, filePath path: String, completion: @escaping getFileMetadataCompletion)
    func downlodFile(projectId: String, start: Int64?, length: Int64?, from: String, to: String, forViewer: Bool, progressHandler: @escaping progressCompletion, completion: @escaping downloadFileCompletion, fileNameHandler: @escaping ((String?) -> Void)) -> NXProjectRestOperation?
    
    // Cancel operation
    func cancelDownloadOrUploadFile(op: NXProjectRestOperation)
    
// MARK: Project Member Operation
    func projectInvitation(project: NXProject, emails: [String], completion: @escaping projectInvitationCompletion)
    func sendInvitationReminder(invitationId: String, completion: @escaping sendInvitationReminderCompletion)
    func revokeInvitation(invitationId: String, completion: @escaping revokeInvitationCompletion)
    func acceptInvitation(invitationId: String, code: String, completion: @escaping acceptInvitationCompletion)
    func declineInvitation(invitationId: String, code: String, declineReason: String?, completion: @escaping declineInvitationCompletion)
    func listMember(projectId: String, filter: NXProjectMemberFilter, completion: @escaping listMemberCompletion)
    func removeMember(projectId: String, memberId: String, completion: @escaping removeMemberCompletion)
    func getMemberDetails(projectId: String, memberId: String, completion: @escaping getMemberDetailsCompletion)
    func listPendingInvitationForProject(projectId: String, filter: NXProjectPendingInvitationFilter, completion: @escaping listPendingInvitationForProjectCompletion)
    func listPendingInvitationForUser(completion: @escaping listPendingInvitationForUserCompletion)
    
    // MARK: project completion handler
    typealias listProjectCompletion = (NXListProjectFilter, Int, [NXProject]?, Error?) -> Void
    typealias getProjectMetadataCompletion = (String, NXProject?, Error?) -> Void
    typealias createProjectCompletion = (String, String?, Error?) -> Void
    typealias updateProjectCompletion = (NXProject?, Error?) -> Void
    typealias uploadFileCompletion = (String, String, NXProjectFileItem?, Error?) -> Void
    typealias progressCompletion = (Double) -> Void
    typealias listFileCompletion = (String, NXProjectFileFilter, [NXProjectFileItem]?, Error?) -> Void
    typealias createFolderCompletion = (String, String, NXProjectFileItem?, Error?) -> Void
    typealias deleteFileCompletion = (String, String, Error?) -> Void
    typealias getFileMetadataCompletion = (String , String, NXProjectFileDetailItem?, Error?) -> Void
    typealias downloadFileCompletion = (String, String, String, Error?) -> Void
    typealias projectInvitationCompletion = (String, [String], [String]?, [String]?, [String]?, Error?) -> Void
    typealias sendInvitationReminderCompletion = (String, Error?) -> Void
    typealias revokeInvitationCompletion = (String, Error?) -> Void
    typealias acceptInvitationCompletion = (String, String, String?, Error?) -> Void
    typealias declineInvitationCompletion = (String, String, Error?) -> Void
    typealias listMemberCompletion = (String, NXProjectMemberFilter, [NXProjectMember]?, Error?) -> Void
    typealias removeMemberCompletion = (String, String, Error?) -> Void
    typealias getMemberDetailsCompletion = (String, String, NXProjectMember?, Error?) -> Void
    typealias listPendingInvitationForProjectCompletion = (String, NXProjectPendingInvitationFilter, [NXProjectInvitation]?, Error?) -> Void
    typealias listPendingInvitationForUserCompletion = ([NXProjectInvitation]?, Error?) -> Void
    
}

extension NXProjectRestProvider: NXProjectRestProviderOperation {
    
    func listProject(filter: NXListProjectFilter, completion: @escaping NXProjectRestProviderOperation.listProjectCompletion) {
        
        let api = NXProjectRestAPI(type: .listProject)
        
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        let parameter: [String: Any] = ["filter": filter]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var projects: [NXProject]?
            var totalNum: Int = 0
            if let response = response as? NXProjectResponse.ListProjectResponse {
                projects = response.projects?.map() { self.convert(from: $0)! }
                totalNum = response.totalProjects
            }
            completion(filter, totalNum, projects, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func getProjectMetadata(withProjectId projectId: String, completion: @escaping NXProjectRestProviderOperation.getProjectMetadataCompletion) {
        
        let api = NXProjectRestAPI(type: .getProjectMetadata)
        
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        let parameter = [RequestParameter.url: ["projectId": projectId]]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var project: NXProject?
            if let response = response as? NXProjectResponse.GetProjectMetadataResponse {
                project = self.convert(from: response.project)
            }
            completion(projectId, project, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func createProject(project: NXProject, invitedEmails: [String]?, completion: @escaping NXProjectRestProviderOperation.createProjectCompletion) {
        
        guard let name = project.name else {
            debugPrint("create project with no name")
            return
        }
        
        let api = NXProjectRestAPI(type: .createProject)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        var body: [String: Any] = ["projectName": name]
        if let description = project.projectDescription {
            body["projectDescription"] = description
        }
        if let invitationMsg = project.invitationMsg {
            body["invitationMsg"] = invitationMsg
        }
        if let invitedEmails = invitedEmails {
            body["emails"] = invitedEmails
        }
        let parameter = [RequestParameter.body: body]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var projectId: String?
            if let response = response as? NXProjectResponse.CreateProjectResponse {
                projectId = response.projectId
            }
            completion(name, projectId, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func updateProject(project: NXProject, completion: @escaping NXProjectRestProviderOperation.updateProjectCompletion) {
        
        guard
            let name = project.name,
            let projectId = project.projectId
            else { return }
        
        let api = NXProjectRestAPI(type: .updateProject)
        let url: [String: Any] = ["projectId": projectId]
        var body: [String: Any] = ["projectName": name]
        if let description = project.projectDescription {
            body["projectDescription"] = description
        }
        if let invitationMsg = project.invitationMsg {
            body["invitationMsg"] = invitationMsg
        }
        let parameter = [RequestParameter.url: url,
                         RequestParameter.body: body]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            let project: NXProject? = {
                if let response = response as? NXProjectResponse.UpdateProjectResponse {
                    return self.convert(from: response.project)
                }
                
                return nil
            }()
            completion(project, error)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func uploadFile(projectId: String, fileName: String, from: String, toFolder: String, property: NXProjectUploadFileProperty, progressHandler: @escaping NXProjectRestProviderOperation.progressCompletion, completion: @escaping NXProjectRestProviderOperation.uploadFileCompletion) ->  NXProjectRestOperation? {
        let api = NXProjectRestAPI(type: .uploadFile)
        // add operation
        let op = NXProjectRestOperation(restAPI: api, projectId: projectId, from: from, to: (toFolder + fileName))
        operationManager.add(element: op)
        
        var rights = "["
        for (index, right) in property.rights.enumerated() {
            if(index > 0) { rights += "," }
            rights += right.description
        }
        rights += "]"
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: from)) else {
            return nil
        }
        let url = ["projectId": projectId]
        var body: [String: Any] = [Constant.kName: fileName,
                                   "rightsJSON": rights,
                                   Constant.kParentPathId: toFolder]
        if let tags = property.tags {
            body["tags"] = tags
        }
        
        let parameter: [String: Any] = [RequestParameter.url: url,
                                        RequestParameter.data: data,
                                        RequestParameter.body: body]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            let item: NXProjectFileItem? = {
                if let response = response as? NXProjectResponse.UploadFileResponse {
                    return response.item
                }
                
                return nil
            }()
            
            completion(projectId, fileName, item, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        api.uploadFile(withParameters: parameter, progress: progressHandler, completion: completion)
        return op
    }
    
    func listFile(projectId: String, filter: NXProjectFileFilter, completion: @escaping NXProjectRestProviderOperation.listFileCompletion) {
        let api = NXProjectRestAPI(type: .listFile)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId, "filter": filter]]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            let items: [NXProjectFileItem]? = {
                if let response = response as? NXProjectResponse.ListFileResponse {
                    return response.items
                }
                return nil
            }()
            completion(projectId, filter, items, error)

            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func createFolder(projectId: String, name: String, parentPath path: String, autorename: Bool, completion: @escaping NXProjectRestProviderOperation.createFolderCompletion) {
        let api = NXProjectRestAPI(type: .createFolder)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        let parameter: [String: Any] = [RequestParameter.url: [Constant.kProjectId: projectId],
                                        RequestParameter.body: [Constant.kParentPathId: path,
                                                                Constant.kName: name,
                                                                Constant.kAutorename: "\(autorename)"]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            let item: NXProjectFileItem? = {
                if let response = response as? NXProjectResponse.CreateFolderResponse {
                    return response.item
                }
                return nil
            }()
            
            completion(projectId, path + name, item, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func deleteFile(projectId: String, filePath path: String, completion: @escaping NXProjectRestProviderOperation.deleteFileCompletion) {
        let api = NXProjectRestAPI(type: .deleteFile)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: [Constant.kProjectId: projectId],
                                        RequestParameter.body: [Constant.kPathId: path]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            _, error in
            
            completion(projectId, path, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func getFileMetadata(projectId: String, filePath path: String, completion: @escaping NXProjectRestProviderOperation.getFileMetadataCompletion) {
        let api = NXProjectRestAPI(type: .getFileMetadata)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: [Constant.kProjectId: projectId],
                                        RequestParameter.body: [Constant.kPathId: path]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            let detailItem: NXProjectFileDetailItem? = {
                if error == nil, let response = response as? NXProjectResponse.GetFileMetadataResponse {
                    return response.item
                }
                return nil
            }()
            
            completion(projectId, path, detailItem, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func downlodFile(projectId: String, start: Int64? = nil, length: Int64? = nil, from: String, to: String, forViewer: Bool, progressHandler: @escaping NXProjectRestProviderOperation.progressCompletion, completion: @escaping NXProjectRestProviderOperation.downloadFileCompletion, fileNameHandler: @escaping ((String?) -> Void)) -> NXProjectRestOperation? {
        let api = NXProjectRestAPI(type: .downloadFile)
        // add operation
        let op = NXProjectRestOperation(restAPI: api, projectId: projectId, from: from, to: to)
        operationManager.add(element: op)
        
        var parameter = [String: Any]()
        
        if let start = start,
            let length = length {
            parameter = [RequestParameter.url: [Constant.kProjectId: projectId],
                         RequestParameter.body: ["start": start,
                                                 "length": length,
                                                 Constant.kPathId: from,
                                                 "forViewer": forViewer]]
            
        } else {
            parameter = [RequestParameter.url: [Constant.kProjectId: projectId],
                         RequestParameter.body: [Constant.kPathId: from,
                                                 "forViewer": forViewer]]
        }
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var destination = to
            if let response = response as? NXProjectResponse.DownloadFileResponse,
                let fileName = response.fileName {
                var destURL = URL(fileURLWithPath: destination)
                destURL.deleteLastPathComponent()
                destURL.appendPathComponent(fileName)
                destination = destURL.path
            }
            
            completion(projectId, from, destination, error)

            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        api.downloadFile(withParameters: parameter, destination: to, progress: progressHandler, completion: completion, fileNameHandler: fileNameHandler)
        return op
    }
    
    func cancelDownloadOrUploadFile(op: NXProjectRestOperation) {
        _ = operationManager.cancel(element: op)
    }
    
    func projectInvitation(project: NXProject, emails: [String], completion: @escaping NXProjectRestProviderOperation.projectInvitationCompletion) {
        
        guard let projectId = project.projectId else {
            debugPrint("no projectId")
            return
        }
        
        let api = NXProjectRestAPI(type: .projectInvitation)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        
        var body: [String: Any] = ["emails": emails]
        if let invitationMsg = project.invitationMsg {
            body["invitationMsg"] = invitationMsg
        }
        
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId],
                                        RequestParameter.body: body
        ]
        
        let completion: (Any?, Error?) -> Void = {
            object, error in
            
            if let response = object as? NXProjectResponse.ProjectInvitationResponse {
                completion(projectId, emails, response.alreadyInvited, response.nowInvited, response.alreadyMembers, error)
            } else {
                completion(projectId, emails, nil, nil, nil, error)
            }
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func sendInvitationReminder(invitationId: String, completion: @escaping NXProjectRestProviderOperation.sendInvitationReminderCompletion) {
        let api = NXProjectRestAPI(type: .sendInvitationReminder)
        let parameter = [RequestParameter.body: ["invitationId": invitationId]]
        let completion: (Any?, Error?) -> Void = {
            _, error in
            completion(invitationId, error)
        }
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func revokeInvitation(invitationId: String, completion: @escaping NXProjectRestProviderOperation.revokeInvitationCompletion) {
        let api = NXProjectRestAPI(type: .revokeInvitation)
        let parameter = [RequestParameter.body: ["invitationId": invitationId]]
        let completion: (Any?, Error?) -> Void = {
            _, error in
            completion(invitationId, error)
        }
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func acceptInvitation(invitationId: String, code: String, completion: @escaping NXProjectRestProviderOperation.acceptInvitationCompletion) {
        let api = NXProjectRestAPI(type: .acceptInvitation)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter = [RequestParameter.url: ["invitation_id": invitationId, "code": code]]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var projectId: String?
            if error == nil, let response = response as? NXProjectResponse.AcceptInvitationResponse {
                projectId = response.projectId
            }
            completion(invitationId, code, projectId, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func declineInvitation(invitationId: String, code: String, declineReason: String?, completion: @escaping NXProjectRestProviderOperation.declineInvitationCompletion) {
        let api = NXProjectRestAPI(type: .declineInvitation)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        var body = ["id": invitationId, "code": code]
        if let declineReason = declineReason {
            body["declineReason"] = declineReason
        }
        let parameter: [String: Any] = [RequestParameter.body: body]
        
        let completion: (Any?, Error?) -> Void = {
            _, error in
            
            completion(invitationId, code, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func listMember(projectId: String, filter: NXProjectMemberFilter, completion: @escaping NXProjectRestProviderOperation.listMemberCompletion) {
        let api = NXProjectRestAPI(type: .listMember)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId,
                                                               "filter": filter]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var members: [NXProjectMember]?
            if error == nil, let response = response as? NXProjectResponse.ListMemberResponse {
                members = response.members?.map() { self.convert(from: $0)! }
            }
            completion(projectId, filter, members, error)

            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func removeMember(projectId: String, memberId: String, completion: @escaping NXProjectRestProviderOperation.removeMemberCompletion) {
        let api = NXProjectRestAPI(type: .removeMember)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId],
                                        RequestParameter.body: ["memberId": memberId]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            _, error in
            completion(projectId, memberId, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func getMemberDetails(projectId: String, memberId: String, completion: @escaping NXProjectRestProviderOperation.getMemberDetailsCompletion) {
        let api = NXProjectRestAPI(type: .getMemberDetail)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId,
                                                               "memberId": memberId]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var member: NXProjectMember?
            if error == nil, let response = response as? NXProjectResponse.GetMemberDetailResponse {
                member = self.convert(from: response.member)
            }
            completion(projectId, memberId, member, error)
            
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func listPendingInvitationForProject(projectId: String, filter: NXProjectPendingInvitationFilter, completion: @escaping NXProjectRestProviderOperation.listPendingInvitationForProjectCompletion) {
        let api = NXProjectRestAPI(type: .listPendingInvitationForProject)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let parameter: [String: Any] = [RequestParameter.url: ["projectId": projectId,
                                                               "filter": filter]
        ]
        
        let completion: (Any?, Error?) -> Void = {
            response, error in
            var pendingList: [NXProjectInvitation]?
            if error == nil, let response = response as? NXProjectResponse.ListPendingInvitationForProjectResponse {
                pendingList = response.invitations?.map() { self.convert(from: $0)! }
            }
            completion(projectId, filter, pendingList, error)
    
            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func listPendingInvitationForUser(completion: @escaping NXProjectRestProviderOperation.listPendingInvitationForUserCompletion) {
        let api = NXProjectRestAPI(type: .listPendingInvitationForUser)
        // add operation
        let op = NXProjectRestOperation(restAPI: api)
        operationManager.add(element: op)
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var pendingList: [NXProjectInvitation]?
            if error == nil, let response = response as? NXProjectResponse.ListPendingInvitationForUserResponse {
                pendingList = response.invitations?.map() { self.convert(from: $0)! }
            }
            completion(pendingList, error)

            // remove operation
            _ = self.operationManager.remove(element: op)
        }
        
        
        api.sendRequest(withParameters: nil, completion: completion)
    }
}

class NXProjectRestProvider {
    
    fileprivate struct Constant {
        static let kParentPathId = "parentPathId"
        static let kName = "name"
        static let kAutorename = "autorename"
        static let kPathId = "pathId"
        static let kProjectId = "projectId"
    }
    
    init(withUserID userID: String, ticket: String) {
        NXProjectRestAPI.setting(withUserID: userID, ticket: ticket)
    }

    var operationManager = NXRestOperationManager<NXProjectRestOperation>()
    
    fileprivate func convert(from nProject: NXNetworkProject?) -> NXProject? {
        guard let nProject = nProject else {
            return nil
        }
        
        let project = NXProject()
        project.projectId = nProject.projectId
        project.name = nProject.name
        project.projectDescription = nProject.projectDescription
        project.displayName = nProject.displayName
        project.creationTime = Date(timeIntervalSince1970: nProject.creationTime)
        project.totalMembers = nProject.totalMembers
        project.totalFiles = nProject.totalFiles
        project.ownedByMe = nProject.ownedByMe
        project.accountType = nProject.accountType
        project.trialEndTime = Date(timeIntervalSince1970: nProject.trialEndTime)
        project.invitationMsg = nProject.invitationMsg
        
        project.owner = nProject.owner
        
        project.projectMembers = nProject.projectMembers?.map() { convert(from: $0)! }
        
        return project
    }
    
    fileprivate func convert(from nMember: NXNetworkProjectMember?) -> NXProjectMember? {
        guard let nMember = nMember else {
            return nil
        }
        
        let member = NXProjectMember()
        member.userId = nMember.userId
        member.displayName = nMember.displayName
        member.email = nMember.email
        member.creationTime = nMember.creationTime
        member.inviterEmail = nMember.inviterEmail
        member.inviterDisplayName = nMember.inviterDisplayName
        member.avatarBase64 = nMember.avatarBase64
        return member
    }
    
    fileprivate func convert(from nInvitation: NXNetworkProjectInvitation?) -> NXProjectInvitation? {
        guard let nInvitation = nInvitation else {
            return nil
        }
        
        let invitation = NXProjectInvitation()
        invitation.invitationId = nInvitation.invitationId
        invitation.inviteeEmail = nInvitation.inviteeEmail
        invitation.inviterEmail = nInvitation.inviterEmail
        invitation.inviterDisplayName = nInvitation.inviterDisplayName
        invitation.inviteTime = nInvitation.inviteTime
        invitation.code = nInvitation.code
        invitation.invitationMsg = nInvitation.invitationMsg
        
        invitation.project = convert(from: nInvitation.project)
        
        return invitation
    }
}
