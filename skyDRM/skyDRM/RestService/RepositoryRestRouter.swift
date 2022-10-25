//
//  RepositoryRestRouter.swift
//  skyDRM
//
//  Created by pchen on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation


enum RepositoryRestRouter {
    
    case addRepository(object: Any)
    case getRepositories
    case updateRepository(object: Any)
    case removeRepository(object: Any)
    
}

extension RepositoryRestRouter: RestRouter {
    
    static var baseURLString = hostURLString + "/rs/repository"
    
    var method: HttpMethod {
        switch self {
        case .addRepository:
            return .post
        case .getRepositories:
            return .get
        case .updateRepository:
            return .put
        case .removeRepository:
            return .delete
        }
    }
    
    var path: String? {
        return ""
    }
    
    init(requestType: Int, object: Any?) throws {
        
        let type = RepositoryRestAPI.RepositoryRestAPIType(rawValue: requestType)!
        switch type {
        case .addRepository:
            self = RepositoryRestRouter.addRepository(object: object!)
        case .getRepositories:
            self = RepositoryRestRouter.getRepositories
        case .updateRepository:
            self = RepositoryRestRouter.updateRepository(object: object!)
        case .removeRepository:
            self = RepositoryRestRouter.removeRepository(object: object!)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try RepositoryRestRouter.baseURLString.asURL()
        var urlRequest = URLRequest(url: url)
        
        urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json",
                                          "consumes": "application/json",
                                          "userId": RepositoryRestAPI.userID,
                                          "ticket": RepositoryRestAPI.ticket,
                                          "platformId": "\(NXCommonUtils.getPlatformId())"
        ]
        
        urlRequest.httpMethod = method.description
        
        switch self {
        case .addRepository(let object):
            
            guard let repoItem = object as? NXRMCRepoItem else {
                break
            }
            
            let repoInfoString = "{\"name\":\"\(repoItem.name)\",\"type\":\"\(repoItem.type.rmsDescription)\",\"isShared\":\(repoItem.isShared),\"accountName\":\"\(repoItem.accountName)\",\"accountId\":\"\(repoItem.accountId)\",\"token\":\"\(repoItem.token)\",\"preference\":\"\",\"creationTime\":\(Int64(Date().timeIntervalSince1970) * 1000)}"
            
            
            let deviceDic = ["deviceId": NXCommonUtils.deviceID(), "deviceType": "MACOS", "repository": repoInfoString]
            let jsonDict = ["parameters": deviceDic]
            
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
            
            urlRequest.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        case .getRepositories:
            break
        case .updateRepository(let object):
            guard let repoItem = object as? NXRMCRepoItem else {
                break
            }
            let deviceDic = ["deviceId": NXCommonUtils.deviceID(), "deviceType": "MACOS", "repoId": repoItem.repoId, "token": repoItem.token, "name": repoItem.name]
            let jsonDict = ["parameters": deviceDic]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .removeRepository(let object):
            guard let repoItem = object as? NXRMCRepoItem else {
                break
            }
            let deviceDic = ["deviceId": NXCommonUtils.deviceID(), "deviceType": "MACOS", "repoId": repoItem.repoId]
            let jsonDict = ["parameters": deviceDic]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        }
        return urlRequest
    }
}
