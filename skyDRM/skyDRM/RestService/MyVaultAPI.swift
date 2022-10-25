//
//  MyVaultAPI.swift
//  skyDRM
//
//  Created by pchen on 25/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

class MyVaultAPI: RestAPI {
    
    enum MyVaultAPIType: Int {
        case listFile
        case uploadFile
        case deleteFile
        case downloadFile
        case getMetadata
    }
    
    init(withType type: MyVaultAPIType) {
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try MyVaultRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = MyVaultResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
    override func generateMultipartFormData(withParameters parameters: Any?) -> [UploadPartFormData]? {
        
        guard
            let dic = parameters as? [String: Any],
            let fileName = dic[RequestParameter.name] as? String,
            let fileData = dic[RequestParameter.data] as? Data,
            let fileInfo = dic[RequestParameter.body]
            else { return nil }
        
        let infoDic = [RequestParameter.kParameters: fileInfo]
        let jsonData = try? JSONSerialization.data(withJSONObject: infoDic, options: .prettyPrinted)
        
        guard let nonilData = jsonData else {
            return nil
        }
        
        let fileFormData = UploadPartFormData(name: RequestParameter.kMultipartFile, data: fileData, fileName: fileName, mimeType: "nextlabs/x-nxl")
        let apiInputFormData = UploadPartFormData(name: RequestParameter.kMultipartFileInfo, data: nonilData, fileName: nil, mimeType: nil)
        return [fileFormData, apiInputFormData]
    }
}
