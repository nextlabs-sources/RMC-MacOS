//
//  ConvertFileRouter.swift
//  skyDRM
//
//  Created by xx-huang on 17/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum ConvertFileRouter {
    case convertFile(dic:[String: Any])
}

extension ConvertFileRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = ConvertFileRestAPI.ConvertFileRestAPIType(rawValue: requestType)!
        
        guard let dic = object as? [String: Any]? else {
            throw BackendError.badRequest(reason: "parameter error")
        }
        
        switch type {
        case .convertFile:
            self = ConvertFileRouter.convertFile(dic: dic!)
        }
    }
    
    static var baseURLString = hostURLString + "/rs/convert/v2"
    
    var method: HttpMethod {
        switch self {
        case .convertFile:
            return .post
        }
    }
    
    var path: String? {
        switch self {
        case .convertFile( _):
            return "/file"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try ConvertFileRouter.baseURLString.asURL()
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.description
        
        switch self {
            
        case .convertFile(let dic):
            
            if let url = dic[RequestParameter.url] as? [String: Any], let fileName = url["fileName"] as? String, let toFormat = url["toFormat"] as? String,let fileData = url["fileData"] as? NSData {
                var components = URLComponents(string: (urlRequest.url?.absoluteString)!)
                var items = [URLQueryItem]()
                
                let fileName = URLQueryItem(name: "fileName", value: fileName)
                items.append(fileName)
                
                let toFormat = URLQueryItem(name: "toFormat", value: toFormat)
                items.append(toFormat)
                
                components?.queryItems = items
                urlRequest.url = try components?.asURL()
                
                urlRequest.httpBody = fileData as Data
                
                let fileContentLength:String = "\(fileData.length)"
                urlRequest.allHTTPHeaderFields = ["Content-Type": "application/octet-stream",
                                                  "Content-Length": fileContentLength,
                                                  "userId": ConvertFileRestAPI.userID,
                                                  "ticket": ConvertFileRestAPI.ticket]
            }
        }
        return urlRequest
    }
}

