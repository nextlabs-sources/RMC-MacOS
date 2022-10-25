//
//  RepositoryRestAPI.swift
//  skyDRM
//
//  Created by pchen on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class RepositoryRestAPI: RestAPI {
    
    enum RepositoryRestAPIType: Int {
        case addRepository
        case getRepositories
        case updateRepository
        case removeRepository
    }
    
    init(type: RepositoryRestAPIType) {
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try RepositoryRestRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = RepositoryRestResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}
