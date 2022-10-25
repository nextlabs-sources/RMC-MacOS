//
//  MyDriveRouter.swift
//  skyDRM
//
//  Created by pchen on 06/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum MyDriveRouter {
    case listFiles(object: Any)
    case uploadFile
    case downloadFile(object: Any)
    case rangeDownloadFile(object: Any)
    case createFolder(object: Any)
    case deleteItem(object: Any)
    case createPublicShareURL(object: Any)
    case search(object: Any)
    case copy(object: Any)
    case move(object: Any)
    case getStorageUsed
    
}

extension MyDriveRouter: RestRouter {

    init(requestType: Int, object: Any?) throws {
        
        let type = MyDriveAPI.MyDriveAPIType(rawValue: requestType)!
        
        switch type {
        case .listFiles:
            self = MyDriveRouter.listFiles(object: object!)
        case .downloadFile:
            self = MyDriveRouter.downloadFile(object: object!)
        case .rangeDownloadFile:
            self = MyDriveRouter.rangeDownloadFile(object: object!)
        case .copy:
            self = MyDriveRouter.copy(object: object!)
        case .createFolder:
            self = MyDriveRouter.createFolder(object: object!)
        case .createPublicShareURL:
            self = MyDriveRouter.createPublicShareURL(object: object!)
        case .deleteItem:
            self = MyDriveRouter.deleteItem(object: object!)
        case .move:
            self = MyDriveRouter.move(object: object!)
        case .search:
            self = MyDriveRouter.search(object: object!)
        case .uploadFile:
            self = MyDriveRouter.uploadFile
        case .getStorageUsed:
            self = MyDriveRouter.getStorageUsed
        }
    }
    
    static var baseURLString = hostURLString + "/rs/myDrive"
    
    var method: HttpMethod {
        return .post
    }
    
    var path: String? {
        switch self {
        case .listFiles:
            return "/list"
        case .uploadFile:
            return "/uploadFile"
        case .downloadFile:
            return "/download"
        case .rangeDownloadFile:
            return "/download"
        case .createFolder:
            return "/createFolder"
        case .deleteItem:
            return "/delete"
        case .createPublicShareURL:
            return "/getPublicUrl"
        case .search:
            return "/search"
        case .copy:
            return "/copy"
        case .move:
            return "/move"
        case .getStorageUsed:
            return "/getUsage"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: MyDriveRouter.baseURLString) else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        guard let path = path else {
            throw BackendError.badRequest(reason: "error url path!")
        }
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        
        urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json",
                                          "consumes": "application/json",
                                          "userId": MyDriveAPI.userID,
                                          "ticket": MyDriveAPI.ticket
        ]
        
        urlRequest.httpMethod = method.description
        
        switch self {
        case .listFiles(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .downloadFile(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .rangeDownloadFile(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .createFolder(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .deleteItem(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .createPublicShareURL(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .search(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .copy(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .move(let object):
            let jsonDict = ["parameters": object]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
        case .getStorageUsed:
            let jsonDict = ["parameters": ["userId": MyDriveAPI.userID, "ticket": MyDriveAPI.ticket]]
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            urlRequest.httpBody = data
            
        default:
            break
        }
        
        return urlRequest
    }
}
