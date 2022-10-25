//
//  UserRestAPI.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/21.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class UserRestAPI: RestAPI {
    enum UserRestAPIType: Int {
        case getCaptcha
        case resetPassword
        case updateProfile
        case getProfile
        case changePassword
    }
    
    init(type: UserRestAPIType) {
        super.init(apiType: type.rawValue)
    }
    override func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        let router = try UserRouter(requestType: apiType, object: parameters)
        return try router.asURLRequest()
    }
    override func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        let response = UserResponse(responseType: apiType, completion: completion)
        let handler = response.handler
        response.handler = nil
        return handler
    }
    
}
