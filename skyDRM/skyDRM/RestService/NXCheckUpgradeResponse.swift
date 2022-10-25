//
//  NXSharedWIthMeResponse.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXCheckUpgradeResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = NXCheckUpgradeAPI.NXCheckUpgradeAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .upgrade:
            return NXCheckUpgradeResponse.UpgradeResponse(response: response, representation: representation)
        }
    }
    
    struct UpgradeResponse: ResponseObjectSerializable {
        var newVersion: String?
        var downloadURL: String?
        var sha1Checksum: String?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else { return nil }
            
            newVersion = results["newVersion"] as? String
            downloadURL = results["downloadURL"] as? String
            sha1Checksum = results["sha1Checksum"] as? String
            
        }
    }
}
