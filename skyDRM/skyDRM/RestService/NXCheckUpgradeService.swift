//
//  NXUpgradeCenter.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 28/08/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXCheckUpgradeService {
    
    static func checkforUpdate(with responseHandler: @escaping (String?, String?,  Error?) -> Void) {
        let api = NXCheckUpgradeAPI(with: .upgrade)
        let completion: CallBack = {
            response, error in
            var newVersion: String?
            var downloadURL: String?
            
            if let response = response as? NXCheckUpgradeResponse.UpgradeResponse {
                newVersion = response.newVersion
                downloadURL = response.downloadURL
            }
            
            responseHandler(newVersion, downloadURL, error)
        }
        
        api.sendRequest(withParameters: nil, completion: completion)
        
    }
    
}
