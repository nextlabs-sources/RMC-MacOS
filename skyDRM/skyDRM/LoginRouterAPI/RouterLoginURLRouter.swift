//
//  RouterLoginURLRouter.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 26/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

enum RouterLoginURLRouter {
    case getServerLoginURL
}

extension RouterLoginURLRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = RouterLoginURLAPI.RouterLoginURLAPIType(rawValue: requestType)!
        
        switch type {
        case .getServerLoginURL:
            self = RouterLoginURLRouter.getServerLoginURL
        }
    }
    
    static var baseURLString = hostURLString + "/router/rs/q/defaultTenant"
    
    var method: HttpMethod {
        switch self {
        case .getServerLoginURL:
            return .get
        }
    }
    
    var path: String? {
        switch self {
        case .getServerLoginURL:
            return ""
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try RouterLoginURLRouter.baseURLString.asURL()
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.description
        
        switch self {
        
        case .getServerLoginURL:

            urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json",
                                              "consumes": "application/json",
                                              "userId": LogRestAPI.userID,
                                              "ticket": LogRestAPI.ticket]

          
            let components = URLComponents(string: (urlRequest.url?.absoluteString)!)
            urlRequest.url = try components?.asURL()
        
        }
        return urlRequest
    }
}
