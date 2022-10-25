//
//  NXSharedWIthMeResponse.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSharedWithMeResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = NXSharedWithMeAPI.NXSharedWithMeAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .listFile:
            return NXSharedWithMeResponse.ListFileResponse(response: response, representation: representation)
        case .reshareFile:
            return NXSharedWithMeResponse.ResharedFileResponse(response: response, representation: representation)
        case .downloadFile:
            return NXSharedWithMeResponse.DownloadFileResponse(response: response, representation: representation)
        }
    }
    
    struct ListFileResponse: ResponseObjectSerializable {
        
        var items: [NXSharedWithMeFileItem]
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any],
                let files = detail["files"] as? [[String: Any]]
                else { return nil }
            
            items = files.map() { NXSharedWithMeFileItem(with: $0) }
        }
    }
    
    struct ResharedFileResponse: ResponseObjectSerializable {
        
        var newTransactionId: String?
        var sharedLink: String?
        var alreadySharedList: [String]?
        var newSharedList: [String]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else { return nil }
            
            if let newTransactionId = results["newTransactionId"] as? String {
                self.newTransactionId = newTransactionId
            }
            if let sharedLink = results["sharedLink"] as? String {
                self.sharedLink = sharedLink
            }
            if let alreadySharedList = results["alreadySharedList"] as? [String] {
                self.alreadySharedList = alreadySharedList
            }
            if let newSharedList = results["newSharedList"] as? [String] {
                self.newSharedList = newSharedList
            }
        }
    }
    
    struct DownloadFileResponse: ResponseObjectSerializable {
        var filename: String?
        
        init?(response: HTTPURLResponse, representation: Any) {
            filename = response.suggestedFilename
        }
    }
}
