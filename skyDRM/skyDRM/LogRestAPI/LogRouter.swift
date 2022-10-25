//
//  LogRouter.swift
//  skyDRM
//
//  Created by xx-huang on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum LogRouter {
    case getActivitylogInfo(dic:[String: Any])
    case putActivitylogInfo(dic:[String: Any])
}

extension LogRouter: RestRouter {
    init(requestType: Int, object: Any?) throws{
        let type = LogRestAPI.LogRestAPIType(rawValue: requestType)!
        
        guard let dic = object as? [String: Any]? else {
            throw BackendError.badRequest(reason: "parameter error")
        }
        
        switch type {
        case .getActivityLogInfo:
            self = LogRouter.getActivitylogInfo(dic: dic!)
        case .putActivityLogInfo:
            self = LogRouter.putActivitylogInfo(dic: dic!)
        }
    }
    
   static var baseURLString = hostURLString + "/rs/log/v2/activity"
    
    var method: HttpMethod {
        switch self {
        case .getActivitylogInfo:
            return .get
        case .putActivitylogInfo:
            return .put
        }
    }
    
    var path: String? {
        switch self {
        case .getActivitylogInfo(let dic):
            guard let url = dic[RequestParameter.url] as? [String: Any], let duid = url["duid"] else {
                return nil
            }
            return "/\(duid)"
            
        case .putActivitylogInfo( _):
            return ""
      }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try LogRouter.baseURLString.asURL()
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.description
        
        switch self {
            
        case .getActivitylogInfo(let dic):
            
            urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json",
                                              "consumes": "application/json",
                                              "userId": LogRestAPI.userID,
                                              "ticket": LogRestAPI.ticket]
            
            if let url = dic[RequestParameter.url] as? [String: Any], let filter = url["filter"] as? Queryable {
                var components = URLComponents(string: (urlRequest.url?.absoluteString)!)
                components?.queryItems = filter.createQueryItems()
                urlRequest.url = try components?.asURL()
            }
            
        case .putActivitylogInfo(let dic):
            
            urlRequest.allHTTPHeaderFields = ["consume": "text/csv",
                                              "Content-Encoding":"gzip",
                                              "userId": LogRestAPI.userID,
                                              "ticket": LogRestAPI.ticket]
            
            let parameters = dic[RequestParameter.kParameters] as! NXPutActivityLogInfoRequestModel
            
            let deviceId = Host.current().localizedName
            let platformId: Int = NXCommonUtils.getPlatformId()
            
            let body:[String] = [parameters.duid!,parameters.owner!,parameters.userID!,String(parameters.operation!),deviceId!,String(platformId),parameters.repositoryId!,parameters.filePathId!,parameters.fileName!,parameters.filePath!,APPLICATION_NAME,APPLICATION_PUBLISHER,APPLICATION_PATH,String(parameters.accessResult!),String(parameters.accessTime),parameters.activityData!]
            
            var data = NXCommonUtils.CSVStringtoData(input: body)
            
            data = data.gzip() as NSData
            urlRequest.httpBody = data as Data
}
        return urlRequest
    }
}
