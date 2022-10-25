//
//  NXSharedWithMeRouter.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

extension NXSharedWithMeRouter {
    
    static var baseURLString = hostURLString + "/rs/sharedWithMe"
    
    var path: String? {
        switch type {
        case .listFile:
            return "/list"
        case .reshareFile:
            return "/reshare"
        case .downloadFile:
            return "/download"
        }
    }
    
    var method: HttpMethod {
        switch type {
        case .listFile:
            return .get
        case .reshareFile:
            return .post
        case .downloadFile:
            return .post
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard
            let url = URL(string: NXSharedWithMeRouter.baseURLString),
            let path = path
            else { throw BackendError.badRequest(reason: Constant.pathWarningMessage) }
        
        guard
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            else { throw BackendError.badRequest(reason: Constant.headerWarningMessage) }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json",
                                       "userId": userId,
                                       "ticket": ticket]
        
        switch type {
        case .listFile:
            if let str = request.url?.absoluteString,
                let filter = parameter?[RequestParameter.filter] as? Queryable {
                var components = URLComponents(string: str)
                components?.queryItems = filter.createQueryItems()
                request.url = components?.url
            }
            break
            
        case .reshareFile,
             .downloadFile:
            if let body = parameter?[RequestParameter.body] {
                let parameters = [RequestParameter.kParameters: body]
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } else {
                // error
            }
        }
        
        return request
    }
}

class NXSharedWithMeRouter {
    
    fileprivate struct Constant {
        static let pathWarningMessage = "path error!"
        static let headerWarningMessage = "no userId or ticket!"
    }
    
    var type: NXSharedWithMeAPI.NXSharedWithMeAPIType
    var parameter: [String: Any]?
    
    init(with type: NXSharedWithMeAPI.NXSharedWithMeAPIType, parameter: [String: Any]?) {
        self.type = type
        self.parameter = parameter
    }
}
