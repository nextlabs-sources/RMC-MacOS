//
//  RepositoryFileRouter.swift
//  skyDRM
//
//  Created by pchen on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum RepositoryFileRouter {
    case getFavFile(dic: [String: Any])
    case markFavFile(dic: [String: Any])
    case unmarkFavFile(dic: [String: Any])

    case getAllFavFile
    
}

extension RepositoryFileRouter: RestRouter {
    
    init(requestType: Int, object: Any?) throws {
        let type = RepositoryFileAPI.RepositoryFileAPIType(rawValue: requestType)!
        
        let dic = object as? [String: Any]
        
        switch type {
        case .getFavFile:
            self = .getFavFile(dic: dic!)
        case .markFavFile:
            self = .markFavFile(dic: dic!)
        case .unmarkFavFile:
            self = .unmarkFavFile(dic: dic!)
            
        case .getAllFavFile:
            self = .getAllFavFile
        }
    }
    
    static var baseURLString: String = hostURLString + "/rs/favorite"//hostURLString + "/rms/rs/repository"
    
    var path: String? {
        switch self {
        case .getFavFile(let dic),
             .markFavFile(let dic),
             .unmarkFavFile(let dic):
              
            guard let url = dic[RequestParameter.url] as? [String: Any], let repoId = url["repoId"] else {
                return nil
            }
            return "/\(repoId)"
            
        case .getAllFavFile:
            return ""
        }
        
    }
    
    var method: HttpMethod {
        switch self {
        case .markFavFile:
            return .post
        case .unmarkFavFile:
            return .delete
        default:
            return .get
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        guard let url = URL(string: RepositoryFileRouter.baseURLString)?.appendingPathComponent(path) else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json",
                                       "userId": RestAPI.userID,
                                       "ticket": RestAPI.ticket]
        
        switch self {
        case .getFavFile(let dic):
            if let filter = dic[RequestParameter.filter] as? Queryable {
                var components = URLComponents(string: url.absoluteString)
                components?.queryItems = filter.createQueryItems()
                request.url = components?.url
            }

        case .markFavFile(let dic),
             .unmarkFavFile(let dic):
        
            let body = dic[RequestParameter.body]
            let parameters = [RequestParameter.kParameters: body]
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        default:
            break
        }
        
        return request
    }
}
