//
//  MyVaultRouter.swift
//  skyDRM
//
//  Created by pchen on 25/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Alamofire

enum MyVaultRouter {
    case listFile(dic: [String: Any])
    case uploadFile
    case deleteFile(dic: [String: Any])
    case downloadFile(dic: [String: Any])
    case getMetadata(dic: [String: Any])
    
}

extension MyVaultRouter: RestRouter {
    
    static var baseURLString = hostURLString + "/rs/myVault"
    
    var method: HttpMethod {
        switch self {
        case .listFile:
            return .get
        case .uploadFile:
            return .post
        case .deleteFile:
            return .post
        case .getMetadata:
            return .post
        case .downloadFile:
            return .post
        }
    }
    
    var path: String? {
        switch self {
        case .uploadFile:
            return "/upload"
        case .deleteFile(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let duid = url["duid"] else {
                return nil
            }
            return "/\(duid)/delete"
        case .getMetadata(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let duid = url["duid"] else {
                return nil
            }
            return "/\(duid)/metadata"
        case .downloadFile:
            return "/download"
        case .listFile:
            return ""
        }
    }
    
    init(requestType: Int, object: Any?) throws {
        
        let type = MyVaultAPI.MyVaultAPIType(rawValue: requestType)!
        
        let dic = object as? [String: Any]
        switch type {
        case .listFile:
            self = MyVaultRouter.listFile(dic: dic!)
        case .uploadFile:
            self = MyVaultRouter.uploadFile
        case .deleteFile:
            self = MyVaultRouter.deleteFile(dic: dic!)
        case .downloadFile:
            self = MyVaultRouter.downloadFile(dic: dic!)
        case .getMetadata:
            self = MyVaultRouter.getMetadata(dic: dic!)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        guard let url = URL(string: MyVaultRouter.baseURLString) else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json",
                                       "userId": RestAPI.userID,
                                       "ticket": RestAPI.ticket]
        
        switch self {
        case .listFile(let dic):
            if let str = request.url?.absoluteString,
               let filter = dic[RequestParameter.filter] as? Queryable {
                var components = URLComponents(string: str)
                components?.queryItems = filter.createQueryItems()
                request.url = components?.url
            }
            
        case .deleteFile(let dic),
             .downloadFile(let dic),
             .getMetadata(let dic):
            let body = dic[RequestParameter.body]
            let parameters = [RequestParameter.kParameters: body]
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        default:
            break
        }
        
        return request
    }
    
    
}
