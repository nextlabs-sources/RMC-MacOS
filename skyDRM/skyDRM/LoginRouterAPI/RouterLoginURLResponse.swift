//
//  RouterLoginURLResponse.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 26/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class RouterLoginURLResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = RouterLoginURLAPI.RouterLoginURLAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .getServerLoginURL:
            return RouterLoginURLResponse.GetServerLoginURLInfoResponse(response: response, representation: representation)
        }
    }
    
    struct GetServerLoginURLInfoResponse: ResponseObjectSerializable {
        var serverReturnLoginURL: String?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any]
                else { return nil }
            
            guard
                let results = representation["results"] as? [String: Any],
                let RMSServerReturnLoginURL = results["server"] as? String  else { return }
                self.serverReturnLoginURL = RMSServerReturnLoginURL
        }
    }
}

