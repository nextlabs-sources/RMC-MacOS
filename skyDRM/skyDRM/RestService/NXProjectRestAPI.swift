//
//  NXProjectRestAPI.swift
//  skyDRM
//
//  Created by pchen on 14/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectRestAPI: RestAPI {
    enum ProjectRestAPIType: Int {
        case listProject
        case getProjectMetadata
        case createProject
        case updateProject
        case uploadFile
        case listFile
        case createFolder
        case deleteFile
        case getFileMetadata
        case downloadFile
        case projectInvitation
        case sendInvitationReminder
        case revokeInvitation
        case acceptInvitation
        case declineInvitation
        case listMember
        case removeMember
        case getMemberDetail
        case listPendingInvitationForProject
        case listPendingInvitationForUser

    }
    
    init(type: ProjectRestAPIType) {
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try NXProjectRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = NXProjectResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
    override func generateMultipartFormData(withParameters parameters: Any?) -> [UploadPartFormData]? {
        guard
            let dic = parameters as? [String: Any],
            let fileData = dic[RequestParameter.data] as? Data,
            let fileInfo = dic[RequestParameter.body]
            else { return nil }
        
        let infoDic = [RequestParameter.kParameters: fileInfo]
        let jsonData = try? JSONSerialization.data(withJSONObject: infoDic, options: .prettyPrinted)
        
        guard let nonilData = jsonData else {
            return nil
        }
        
        let fileFormData = UploadPartFormData(name: "file", data: fileData, fileName: nil, mimeType: nil)
        let apiInputFormData = UploadPartFormData(name: "API-input", data: nonilData, fileName: nil, mimeType: nil)
        return [fileFormData, apiInputFormData]

    }
}
