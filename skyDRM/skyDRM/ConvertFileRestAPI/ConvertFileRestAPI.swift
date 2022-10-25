//
//  ConvertFileRestAPI.swift
//  skyDRM
//
//  Created by xx-huang on 17/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class ConvertFileRestAPI: RestAPI {
    enum ConvertFileRestAPIType: Int {
        case convertFile
    }
    
    init(type: ConvertFileRestAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try ConvertFileRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = ConvertFileResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}
