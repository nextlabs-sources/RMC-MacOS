//
//  RepositoryFileAPI.swift
//  skyDRM
//
//  Created by pchen on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class RepositoryFileAPI: RestAPI {
    
    enum RepositoryFileAPIType: Int {
        case getFavFile
        case markFavFile
        case unmarkFavFile
        
        case getAllFavFile
    }
    
    init(type: RepositoryFileAPIType) {
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try RepositoryFileRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = RepositoryFileResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
}
