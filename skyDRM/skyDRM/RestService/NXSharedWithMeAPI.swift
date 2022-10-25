//
//  NXSharedWithMeAPI.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSharedWithMeAPI: RestAPI {
    enum NXSharedWithMeAPIType: Int {
        case listFile
        case reshareFile
        case downloadFile
        
    }
    
    var type: NXSharedWithMeAPIType
    
    init(with type: NXSharedWithMeAPIType) {
        self.type = type
        
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        guard let parameters = parameters as? [String: Any]? else {
            throw BackendError.badRequest(reason: "")
        }
        
        let router = NXSharedWithMeRouter(with: type, parameter: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = NXSharedWithMeResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
}
