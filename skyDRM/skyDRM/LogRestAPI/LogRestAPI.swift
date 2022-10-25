//
//  LogRestAPI.swift
//  skyDRM
//
//  Created by xx-huang on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class LogRestAPI: RestAPI {
    enum LogRestAPIType: Int {
        case getActivityLogInfo
        case putActivityLogInfo
    }
    
    init(type: LogRestAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try LogRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = LogResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}
