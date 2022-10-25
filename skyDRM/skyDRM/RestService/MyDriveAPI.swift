//
//  MyDriveAPI.swift
//  skyDRM
//
//  Created by pchen on 06/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class MyDriveAPI: RestAPI {
    
    /// MyDrive API Type
    enum MyDriveAPIType: Int {
        case listFiles
        case uploadFile
        case downloadFile
        case rangeDownloadFile
        case createFolder
        case deleteItem
        case createPublicShareURL
        case search
        case copy
        case move
        case getStorageUsed
    }
    
    init(type: MyDriveAPIType) {
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try MyDriveRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = MyDriveResponse(responseType: apiType, completion: completion)
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
