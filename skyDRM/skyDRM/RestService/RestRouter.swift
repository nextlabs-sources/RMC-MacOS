//
//  RestRouter.swift
//  skyDRM
//
//  Created by pchen on 07/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol Queryable {
    func createQueryItems() -> [URLQueryItem]
}

struct RequestParameter {
    
    static let url = "HttpUrl"
    static let body = "HttpBody"
    static let filter = "Filter"
    
    static let data = "FileData"
    static let name = "FileName"
    
    // parameter
    static let kParameters = "parameters"
    static let kMultipartFile = "file"
    static let kMultipartFileInfo = "API-input"
    
}

enum HttpMethod: CustomStringConvertible {
    case get
    case post
    case delete
    case put
    
    var description: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .delete:
            return "DELETE"
        case .put:
            return "PUT"
        }
    }
}

var hostURLString: String = ""

protocol RestRouter {
    
    static var baseURLString: String { get }
    var path: String? { get }
    var method: HttpMethod { get }
    
    init(requestType: Int, object: Any?) throws
    
    func asURLRequest() throws -> URLRequest
}
