//
//  MyVaultResponse.swift
//  skyDRM
//
//  Created by pchen on 25/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class MyVaultResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        
        guard let type = MyVaultAPI.MyVaultAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .listFile:
            return MyVaultResponse.ListFileResponse(response: response, representation: representation)
        case .uploadFile:
            return MyVaultResponse.UploadFileResponse(response: response, representation: representation)
        case .getMetadata:
            return MyVaultResponse.GetMetadataResponse(response: response, representation: representation)
        case .deleteFile:
            return MyVaultResponse.DeleteFileResponse(response: response, representation: representation)
        case .downloadFile:
            return MyVaultResponse.DownloadFileResponse(response: response, representation: representation)
        }
    }

    struct ListFileResponse: ResponseObjectSerializable {
        var totalCount: Int
        var files: [NXMyVaultFileItem]
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any],
                let totalCount = detail["totalFiles"] as? Int,
                let files = detail["files"] as? [[String: Any]]
                else { return nil }
            
            self.totalCount = totalCount
            self.files = files.map() { NXMyVaultFileItem(withDic: $0)}
        }
    }
    
    struct UploadFileResponse: ResponseObjectSerializable {
        
        var file: NXMyVaultFileItem
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
            else { return nil }
            
            file = NXMyVaultFileItem(withDic: results)
        }
    }
    
    struct GetMetadataResponse: ResponseObjectSerializable {
        
        var file: NXMyVaultDetailFileItem
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let detail = results["detail"] as? [String: Any]
            else { return nil }
            
            file = NXMyVaultDetailFileItem(withDic: detail)
        }
    }
    
    struct DeleteFileResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct DownloadFileResponse: ResponseObjectSerializable {
        var resultData: Data
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard let data = representation as? Data else {
                return nil
            }
            resultData = data
        }
    }
}
