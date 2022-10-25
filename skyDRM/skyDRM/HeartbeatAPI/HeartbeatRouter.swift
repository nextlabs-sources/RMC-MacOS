//
//  HeartbeatRouter.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum HeartbeatRouter {
    case getWaterMarkConfig(dic:[String: Any])
}

extension HeartbeatRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = HeartbeatAPI.HeartbeatAPIType(rawValue: requestType)!
        
        guard let dic = object as? [String: Any]? else {
            throw BackendError.badRequest(reason: "parameter error")
        }
        
        switch type {
        case .getWaterMarkConfig:
            self = HeartbeatRouter.getWaterMarkConfig(dic: dic!)
        }
    }
    
     static var baseURLString = hostURLString + "/rs/v2"
    
    var method: HttpMethod {
        switch self {
        case .getWaterMarkConfig:
            return .post
        }
    }
    
    var path: String? {
        switch self {
        case .getWaterMarkConfig( _):
               return "/heartbeat"
        }
    }
    
    
    func asURLRequest() throws -> URLRequest {
        let url = try HeartbeatRouter.baseURLString.asURL()
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.description
        
        urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json",
                                          "consume": "application/json",
                                          "userId": HeartbeatAPI.userID,
                                          "ticket": HeartbeatAPI.ticket]
        
        switch self {
        case .getWaterMarkConfig(let dic):
            let body = dic[RequestParameter.body]
            let parameters = [RequestParameter.kParameters: body]
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        }
        return urlRequest
    }
}
