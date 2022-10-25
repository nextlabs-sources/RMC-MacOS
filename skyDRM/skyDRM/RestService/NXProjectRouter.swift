//
//  NXProjectRouter.swift
//  skyDRM
//
//  Created by pchen on 14/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXProjectRouter {
    case listProject(dic: [String: Any]?)
    case getProjectMetadata(dic: [String: Any])
    case createProject(dic: [String: Any])
    case updateProject(dic: [String: Any])
    case uploadFile(dic: [String: Any])
    case listFile(dic: [String: Any])
    case createFolder(dic: [String: Any])
    case deleteFile(dic: [String: Any])
    case getFileMetadata(dic: [String: Any])
    case downloadFile(dic: [String: Any])
    case projectInvitation(dic: [String: Any])
    case sendInvitationReminder(dic: [String: Any])
    case revokeInvitation(dic: [String: Any])
    case acceptInvitation(dic: [String: Any])
    case declineInvitation(dic: [String: Any])
    case listMember(dic: [String: Any])
    case removeMember(dic: [String: Any])
    case getMemberDetail(dic: [String: Any])
    case listPendingInvitationForProject(dic: [String: Any])
    case listPendingInvitationForUser
}

extension NXProjectRouter: RestRouter {
    
    static var baseURLString: String = hostURLString + "/rs/project"
    
    var method: HttpMethod {
        switch self {
        case .createProject:
            return .put
        case .uploadFile,
             .createFolder,
             .deleteFile,
             .getFileMetadata,
             .downloadFile,
             .projectInvitation,
             .revokeInvitation,
             .declineInvitation,
             .removeMember,
             .updateProject,
             .sendInvitationReminder:
            return .post
        default:
            return .get
        }
    }
    
    init(requestType: Int, object: Any?) throws {
        
        let type = NXProjectRestAPI.ProjectRestAPIType(rawValue: requestType)!
        
        guard let dic = object as? [String: Any]? else {
            throw BackendError.badRequest(reason: "parameter error")
        }
        switch type {
        case .listProject:
            self = .listProject(dic: dic)
        case .getProjectMetadata:
            self = .getProjectMetadata(dic: dic!)
        case .createProject:
            self = .createProject(dic: dic!)
        case .updateProject:
            self = .updateProject(dic: dic!)
        case .uploadFile:
            self = .uploadFile(dic: dic!)
        case .listFile:
            self = .listFile(dic: dic!)
        case .createFolder:
            self = .createFolder(dic: dic!)
        case .deleteFile:
            self = .deleteFile(dic: dic!)
        case .getFileMetadata:
            self = .getFileMetadata(dic: dic!)
        case .downloadFile:
            self = .downloadFile(dic: dic!)
        case .projectInvitation:
            self = .projectInvitation(dic: dic!)
        case .sendInvitationReminder:
            self = .sendInvitationReminder(dic: dic!)
        case .revokeInvitation:
            self = .revokeInvitation(dic: dic!)
        case .acceptInvitation:
            self = .acceptInvitation(dic: dic!)
        case .declineInvitation:
            self = .declineInvitation(dic: dic!)
        case .listMember:
            self = .listMember(dic: dic!)
        case .removeMember:
            self = .removeMember(dic: dic!)
        case .getMemberDetail:
            self = .getMemberDetail(dic: dic!)
        case .listPendingInvitationForProject:
            self = .listPendingInvitationForProject(dic: dic!)
        case .listPendingInvitationForUser:
            self = .listPendingInvitationForUser
        }
    }
    
    var path: String? {
        switch self {
        case .getProjectMetadata(let dic),
             .updateProject(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)"
        case .uploadFile(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/upload"
        case .listFile(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/files"
        case .createFolder(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/createFolder"
        case .deleteFile(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/delete"
        case .getFileMetadata(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/file/metadata"
        case .downloadFile(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/download"
        case .projectInvitation(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/invite"
        case .sendInvitationReminder:
            return "/sendReminder"
        case .revokeInvitation:
            return "/revokeInvite"
        case .acceptInvitation:
            return "/accept"
        case .declineInvitation:
            return "/decline"
        case .listMember(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/members"
        case .removeMember(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/members/remove"
        case .getMemberDetail(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"], let memberId = url["memberId"] else {
                return nil
            }
            return "/\(projectId)/member/\(memberId)"
        case .listPendingInvitationForProject(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let projectId = url["projectId"] else {
                return nil
            }
            return "/\(projectId)/invitation/pending"
        case .listPendingInvitationForUser:
            return "/user/invitation/pending"
        default:
            return ""
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        guard let url = URL(string: NXProjectRouter.baseURLString) else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json",
                                       "userId": NXProjectRestAPI.userID,
                                       "ticket": NXProjectRestAPI.ticket]
        
        switch self {
        case .listProject(let dic):
            if let filter = dic?["filter"] as? Queryable {
                var components = URLComponents(string: (request.url?.absoluteString)!)
                components?.queryItems = filter.createQueryItems()
                request.url = try components?.asURL()
            }
            
        case .createProject(let dic),
             .createFolder(let dic),
             .deleteFile(let dic),
             .getFileMetadata(let dic),
             .downloadFile(let dic),
             .projectInvitation(let dic),
             .removeMember(let dic),
             .revokeInvitation(let dic),
             .updateProject(let dic),
             .sendInvitationReminder(let dic):
            
            let body = dic[RequestParameter.body]
            let parameters = [RequestParameter.kParameters: body]
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        case .acceptInvitation(let dic):
            if let url = dic[RequestParameter.url] as? [String: Any], let invitationId = url["invitation_id"] as? String, let code = url["code"] as? String {
                var components = URLComponents(string: (request.url?.absoluteString)!)
                var items = [URLQueryItem]()
                
                let invitation_id = URLQueryItem(name: "id", value: invitationId)
                items.append(invitation_id)
                
                let code = URLQueryItem(name: "code", value: code)
                items.append(code)
                
                components?.queryItems = items
                request.url = try components?.asURL()
            }
        case .declineInvitation(let dic):
            
            if let body = dic[RequestParameter.body] as? [String: Any] {
                
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                var parameter = ""
                for (key, value) in body {
                    parameter += "\(key)=\(value)"
                    parameter += "&"
                }
                parameter.remove(at: parameter.index(before: parameter.endIndex))
                request.httpBody = parameter.data(using: .utf8)
            }
            
        case .listFile(let dic),
             .listMember(let dic),
             .listPendingInvitationForProject(let dic):
            
            if let url = dic[RequestParameter.url] as? [String: Any], let filter = url["filter"] as? Queryable {
                var components = URLComponents(string: (request.url?.absoluteString)!)
                components?.queryItems = filter.createQueryItems()
                request.url = try components?.asURL()
            }
            
        default:
            break
        }
        
        return request
    }
}
