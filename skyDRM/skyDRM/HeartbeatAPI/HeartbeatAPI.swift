//
//  HeartbeatAPI.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

import Foundation

class HeartbeatAPI: RestAPI {
    enum HeartbeatAPIType: Int {
        case getWaterMarkConfig
    }
    
    init(type: HeartbeatAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try HeartbeatRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = HeartbeatResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}

