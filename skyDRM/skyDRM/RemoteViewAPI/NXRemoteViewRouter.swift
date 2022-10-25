//
//  RemoteViewRouter.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum NXRemoteViewRouter {
    case viewVDS(dic:[String: Any])
    case viewRepo(dic: [String: Any])
    case viewProject(dic: [String: Any])
}

extension NXRemoteViewRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = NXRemoteViewAPI.NXRemoteViewAPIType(rawValue: requestType)!
        
        guard let dic = object as? [String: Any]? else {
            throw BackendError.badRequest(reason: "parameter error")
        }
        
        switch type {
        case .viewVDS:
            self = NXRemoteViewRouter.viewVDS(dic: dic!)
        case .viewRepo:
            self = NXRemoteViewRouter.viewRepo(dic: dic!)
        case .viewProject:
            self = NXRemoteViewRouter.viewProject(dic: dic!)
        }
    }
    
    static var baseURLString = hostURLString + "/rs/remoteView"
    
    var method: HttpMethod {
        switch self {
        case .viewVDS:
            return .post
        case .viewRepo:
            return .post
        case .viewProject:
            return .post
        }
    }
    
    var path: String? {
        switch self {
        case .viewVDS( _):
            return "/local"
        case .viewRepo( _):
            return "/repository"
        case .viewProject( _):
            return "/project"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        guard let url = URL(string: NXRemoteViewRouter.baseURLString) else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json",
                                       "userId": RestAPI.userID,
                                       "ticket": RestAPI.ticket]
        switch self {
        case .viewRepo(let dic):
            if let body = dic[RequestParameter.body] {
                let parameters = [RequestParameter.kParameters: body]
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            }
        case .viewProject(let dic):
            if let body = dic[RequestParameter.body] {
                let parameters = [RequestParameter.kParameters: body]
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            }
        default:
            break
        }
        
        return request
    }
}
