//
//  RouterLoginURLAPI.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 26/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class RouterLoginURLAPI: RestAPI {
    enum RouterLoginURLAPIType: Int {
        case getServerLoginURL
    }
    
    init(type: RouterLoginURLAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try RouterLoginURLRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = RouterLoginURLResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}
