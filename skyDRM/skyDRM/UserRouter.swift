//
//  UserRouter.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/21.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

enum UserRouter {
    case getCaptcha
    case resetPassword(object: Any)
    case updateProfile(object: Any)
    case getProfile
    case changePassword(object: Any)
}

extension UserRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = UserRestAPI.UserRestAPIType(rawValue: requestType)!
        
        switch type {
        case .getCaptcha:
            self = UserRouter.getCaptcha
        case .resetPassword:
            self = UserRouter.resetPassword(object: object!)
        case .updateProfile:
            self = UserRouter.updateProfile(object: object!)
        case .getProfile:
            self = UserRouter.getProfile
        case .changePassword:
            self = UserRouter.changePassword(object: object!)
        }
    }
    static var baseURLString = hostURLString + "/rs/usr"
    
    var method: HttpMethod {
        switch self {
        case .getCaptcha:
            return .get
        case .resetPassword:
            return .post
        case .updateProfile:
            return .post
        case .getProfile:
            return .get
        case .changePassword:
            return .post
        }
    }
    
    var path: String? {
        switch self {
        case .getCaptcha:
            return "/captcha"
        case .resetPassword:
            return "/resetPassword"
        case .updateProfile:
            return "/profile"
        case .getProfile:
            return "/v2/profile"
        case .changePassword:
            return "changePassword"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try UserRouter.baseURLString.asURL()
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))

        urlRequest.httpMethod = method.description
        
        switch self {
        case .getCaptcha:
            urlRequest.allHTTPHeaderFields = ["consumes": "application/json"]
        case .resetPassword(let object):
            urlRequest.allHTTPHeaderFields = ["consumes": "application/x-www-form-urlencoded"]
            let data = (object as! String).data(using: .utf8)
            urlRequest.httpBody = data
        case .updateProfile(let object):
            urlRequest.allHTTPHeaderFields = ["consumes": "application/json"]
            urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
            urlRequest.allHTTPHeaderFields = ["userId": UserRestAPI.userID]
            urlRequest.allHTTPHeaderFields = ["ticket": UserRestAPI.ticket]
            let property = NSMutableDictionary(dictionary: ["userId": UserRestAPI.userID as Any, "ticket": UserRestAPI.ticket as Any])
            property.addEntries(from: object as! [AnyHashable: Any])
            let jsonDict = ["parameters": property]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .getProfile:
            urlRequest.allHTTPHeaderFields = ["userId": UserRestAPI.userID, "ticket": UserRestAPI.ticket]
        case .changePassword(let object):
            urlRequest.allHTTPHeaderFields = ["consumes": "application/json"]
            urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
            urlRequest.allHTTPHeaderFields = ["userId": UserRestAPI.userID]
            urlRequest.allHTTPHeaderFields = ["ticket": UserRestAPI.ticket]
            let property = object as! [AnyHashable: Any]
            let jsonDict = ["parameters": property]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        }
        
        return urlRequest
    }

}
