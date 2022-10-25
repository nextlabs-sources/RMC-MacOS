//
//  NXSharedWithMeRouter.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

extension NXCheckUpgradeRouter {
    static var baseURLString = "https://rmtest.nextlabs.solutions" + "/rms/rs/"
    
    var path: String? {
        switch type {
        case .upgrade:
            return ""
        }
    }
    
    var method: HttpMethod {
        switch type {
        case .upgrade:
            return .post
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard
            let url = URL(string: NXCheckUpgradeRouter.baseURLString),
            let path = path
            else { throw BackendError.badRequest(reason: Constant.pathWarningMessage) }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.description
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "consumes": "application/json"]
        
        switch type {
        case .upgrade:
            request.url = URL(string: "upgrade?tenant=skydrm", relativeTo: request.url)
            let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            
            let body: [String: Any] = ["platformId": NXCommonUtils.getPlatformId(), "currentVersion": bundleVersion]
            let parameters = [RequestParameter.kParameters: body]
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        }
        
        return request
    }
}

class NXCheckUpgradeRouter {
    
    fileprivate struct Constant {
        static let pathWarningMessage = "path error!"
        static let headerWarningMessage = "no userId or ticket!"
    }
    
    var type: NXCheckUpgradeAPI.NXCheckUpgradeAPIType
    var parameter: [String: Any]?
    
    init(with type: NXCheckUpgradeAPI.NXCheckUpgradeAPIType, parameter: [String: Any]?) {
        self.type = type
        self.parameter = parameter
    }
}
