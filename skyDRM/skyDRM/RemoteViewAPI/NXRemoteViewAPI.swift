//
//  RemoteViewAPI.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXRemoteViewAPI: RestAPI {
    enum NXRemoteViewAPIType: Int {
        case viewVDS
        case viewRepo
        case viewProject
    }
    
    init(type: NXRemoteViewAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try NXRemoteViewRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = NXRemoteViewResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
    override func generateMultipartFormData(withParameters parameters: Any?) -> [UploadPartFormData]? {
        guard
            let dic = parameters as? [String: Any],
            let fileData = dic["fileData"] as? Data,
            let fileInfo = dic["object"]
            else { return nil }
        
        let infoDic = ["parameters": fileInfo]
        let jsonData = try? JSONSerialization.data(withJSONObject: infoDic, options: .prettyPrinted)
        
        guard let nonilData = jsonData else {
            return nil
        }
        
        let fileFormData = UploadPartFormData(name: "file", data: fileData, fileName: nil, mimeType: nil)
        let apiInputFormData = UploadPartFormData(name: "API-input", data: nonilData, fileName: nil, mimeType: nil)
        return [fileFormData, apiInputFormData]
    }
}
