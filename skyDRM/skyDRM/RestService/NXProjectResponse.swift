//
//  NXProjectResponse.swift
//  skyDRM
//
//  Created by pchen on 14/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        let type = NXProjectRestAPI.ProjectRestAPIType(rawValue: responseType)!
        switch type {
        case .listProject:
            return ListProjectResponse(response: response, representation: representation)
        case .getProjectMetadata:
            return GetProjectMetadataResponse(response: response, representation: representation)
        case .createProject:
            return CreateProjectResponse(response: response, representation: representation)
        case .updateProject:
            return UpdateProjectResponse(response: response, representation: representation)
        case .uploadFile:
            return UploadFileResponse(response: response, representation: representation)
        case .listFile:
            return ListFileResponse(response: response, representation: representation)
        case .createFolder:
            return CreateFolderResponse(response: response, representation: representation)
        case .deleteFile:
            return DeleteFileResponse(response: response, representation: representation)
        case .getFileMetadata:
            return GetFileMetadataResponse(response: response, representation: representation)
        case .downloadFile:
            return DownloadFileResponse(response: response, representation: representation)
        case .projectInvitation:
            return ProjectInvitationResponse(response: response, representation: representation)
        case .revokeInvitation:
            return RevokeInvitationResponse(response: response, representation: representation)
        case .acceptInvitation:
            return AcceptInvitationResponse(response: response, representation: representation)
        case .declineInvitation:
            return DeclineInvitationResponse(response: response, representation: representation)
        case .listMember:
            return ListMemberResponse(response: response, representation: representation)
        case .removeMember:
            return RemoveMemberResponse(response: response, representation: representation)
        case .getMemberDetail:
            return GetMemberDetailResponse(response: response, representation: representation)
        case .listPendingInvitationForProject:
            return ListPendingInvitationForProjectResponse(response: response, representation: representation)
        case .listPendingInvitationForUser:
            return ListPendingInvitationForUserResponse(response: response, representation: representation)
        case .sendInvitationReminder:
            return SendReminderResponse(response: response, representation: representation)
        }
    }
    
    struct ListProjectResponse: ResponseObjectSerializable {
        var projects: [NXNetworkProject]?
        var totalProjects: Int = 0
        
        init?(response: HTTPURLResponse, representation: Any) {
            
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let totalNum = results["totalProjects"] as? Int,
                let detail = results["detail"] as? [[String: Any]]
                else { return }
            
            var list = [NXNetworkProject]()
            for dic in detail {
                let project = NXNetworkProject(with: dic)
                list.append(project)
            }
            projects = list
            totalProjects = totalNum
        }
    }
    
    struct GetProjectMetadataResponse: ResponseObjectSerializable {
        var project: NXNetworkProject?
        
        init?(response: HTTPURLResponse, representation: Any) {
            
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any]
                else { return }
            
            project = NXNetworkProject(with: detail)
        }
    }
    
    struct CreateProjectResponse: ResponseObjectSerializable {
        var projectId: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let projectId = results["projectId"] as? Int
                else { return nil }
            
            self.projectId = "\(projectId)"
        }
    }
    
    struct UpdateProjectResponse: ResponseObjectSerializable {
        var project: NXNetworkProject
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any]
                else { return nil }
            
            project = NXNetworkProject(with: detail)
        }
    }
    
    struct UploadFileResponse: ResponseObjectSerializable {
        var item: NXProjectFileItem
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let entry = results["entry"] as? [String: Any]
                else { return nil }
            
            item = NXProjectFileItem(withDictionary: entry)
            
        }
    }
    
    struct ListFileResponse: ResponseObjectSerializable {
        var totalFiles: Int = 0
        var items: [NXProjectFileItem]?
        
        init?(response: HTTPURLResponse, representation: Any) {

            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any],
                let fileArr = detail["files"] as? [[String: Any]],
                let totalFiles = detail["totalFiles"] as? Int
                else { return }
            
            self.totalFiles = totalFiles
            
            items = fileArr.map() {
                NXProjectFileItem(withDictionary: $0)
            }
        }
    }
    
    struct CreateFolderResponse: ResponseObjectSerializable {
        var item: NXProjectFileItem
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let entry = results["entry"] as? [String: Any]
                else { return nil }
            
            item = NXProjectFileItem(withDictionary: entry)
        }
    }
    
    struct DeleteFileResponse: ResponseObjectSerializable {
        var name: String
        var path: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let path = results["pathId"] as? String,
                let name = results["name"] as? String
                else { return nil }
            
            self.name = name
            self.path = path
        }
    }
    
    struct GetFileMetadataResponse: ResponseObjectSerializable {
        var item: NXProjectFileDetailItem?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let fileInfo = results["fileInfo"] as? [String: Any]
                else { return }
            
            item = NXProjectFileDetailItem(withDictionary: fileInfo)
            
        }
    }
    
    struct DownloadFileResponse: ResponseObjectSerializable {
        var resultData: Data?
        var fileName: String?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard let data = representation as? Data else {
                return
            }
            resultData = data
            if response.allHeaderFields[ResponseHeader.kContentDisposition] != nil {
                fileName = response.suggestedFilename
            }
            
        }
    }
    
    struct ProjectInvitationResponse: ResponseObjectSerializable {
        var alreadyInvited: [String]
        var nowInvited: [String]
        var alreadyMembers: [String]
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else { return nil }
            
            alreadyInvited = results["alreadyInvited"] as! [String]
            nowInvited = results["nowInvited"] as! [String]
            alreadyMembers = results["alreadyMembers"] as! [String]
        }
    }
    
    struct SendReminderResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct RevokeInvitationResponse: ResponseObjectSerializable {
        
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct AcceptInvitationResponse: ResponseObjectSerializable {
        var projectId: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let projectId = results["projectId"]
                else { return nil }
            
            self.projectId = "\(projectId)"
        }
    }
    
    struct DeclineInvitationResponse: ResponseObjectSerializable {
        
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct ListMemberResponse: ResponseObjectSerializable {
        var totalMembers: Int = 0
        var members: [NXNetworkProjectMember]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any],
                let totalMembers = detail["totalMembers"] as? Int,
                let membersArr = detail["members"] as? [[String: Any]]
                else { return }
            
            self.totalMembers = totalMembers
            members = membersArr.map() {
                NXNetworkProjectMember(with: $0)
            }
        }
    }
    
    struct RemoveMemberResponse: ResponseObjectSerializable {
        
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct GetMemberDetailResponse: ResponseObjectSerializable {
        var member: NXNetworkProjectMember?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any]
                else { return }
            
            member = NXNetworkProjectMember(with: detail)
        }
    }
    
    struct ListPendingInvitationForProjectResponse: ResponseObjectSerializable {
        var totalInvitations: Int = 0
        var invitations: [NXNetworkProjectInvitation]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let pendingList = results["pendingList"] as? [String: Any],
                let totalInvitations = pendingList["totalInvitations"] as? Int,
                let invitationsArr = pendingList["invitations"] as? [[String: Any]]
                else { return }
            
            self.totalInvitations = totalInvitations
            invitations = invitationsArr.map() {
                NXNetworkProjectInvitation(withDictionary: $0)
            }
        }
    }
    
    struct ListPendingInvitationForUserResponse: ResponseObjectSerializable {
        var invitations: [NXNetworkProjectInvitation]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let invitationsArr = results["pendingInvitations"] as? [[String: Any]]
                else { return }
            
            invitations = invitationsArr.map() {
                NXNetworkProjectInvitation(withDictionary: $0)
            }
        }
    }
}
