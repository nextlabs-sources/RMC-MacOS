//
//  NXSharedWithMeAPI.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXCheckUpgradeAPI: RestAPI {
    enum NXCheckUpgradeAPIType: Int {
        case upgrade
        
    }
    
    var type: NXCheckUpgradeAPIType
    
    init(with type: NXCheckUpgradeAPIType) {
        self.type = type
        
        super.init(apiType: type.rawValue)
    }
    
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        guard let parameters = parameters as? [String: Any]? else {
            throw BackendError.badRequest(reason: "")
        }
        
        let router = NXCheckUpgradeRouter(with: type, parameter: parameters)
        return try router.asURLRequest()
    }
    
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = NXCheckUpgradeResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
}
