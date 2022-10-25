//
//  MyDriveResponse.swift
//  skyDRM
//
//  Created by pchen on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

/// Response Structure

class MyDriveResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        
        guard let type = MyDriveAPI.MyDriveAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .listFiles:
            return MyDriveResponse.ListFilesResponse(response: response, representation: representation)
        case .downloadFile:
            return MyDriveResponse.DownloadFileResponse(response: response, representation: representation)
        case .rangeDownloadFile:
            return MyDriveResponse.RangeDownloadFileResponse(response: response, representation: representation)
        case .copy:
            return MyDriveResponse.CopyResponse(response: response, representation: representation)
        case .createFolder:
            return MyDriveResponse.CreateFolderResponse(response: response, representation: representation)
        case .createPublicShareURL:
            return MyDriveResponse.CreatePublicShareURLResponse(response: response, representation: representation)
        case .deleteItem:
            return MyDriveResponse.DeleteItemResponse(response: response, representation: representation)
        case .move:
            return MyDriveResponse.MoveResponse(response: response, representation: representation)
        case .search:
            return MyDriveResponse.SearchResponse(response: response, representation: representation)
        case .uploadFile:
            return MyDriveResponse.UploadFileResponse(response: response, representation: representation)
        case .getStorageUsed:
            return MyDriveResponse.GetStorageUsedResponse(response: response, representation: representation)
        }
    }
    
    struct ListFilesResponse: ResponseObjectSerializable {
        var items: Array<NXMyDriveFileItem>
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let entries = results["entries"] as? Array<Dictionary<String, Any>>
                else { return nil }
            
            items = entries.map() { NXMyDriveFileItem(withDictionary: $0) }
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
    
    struct RangeDownloadFileResponse: ResponseObjectSerializable {
        var resultData: Data
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard let data = representation as? Data else {
                return nil
            }
            resultData = data
        }
    }
    
    struct UploadFileResponse: ResponseObjectSerializable {
        var item: NXMyDriveFileItem
        var usage: Int64
        var quota: Int64
        var myVaultUsage: Int64
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let entry = results["entry"] as? [String: Any],
                let usage = results["usage"] as? Int64,
                let quota = results["quota"] as? Int64,
                let myVaultUsage = results["myVaultUsage"] as? Int64
                else { return nil }
            
            item = NXMyDriveFileItem(withDictionary: entry)
            self.usage = usage
            self.quota = quota
            self.myVaultUsage = myVaultUsage
        }
    }

    struct CreateFolderResponse: ResponseObjectSerializable {
        
        var item: NXMyDriveFileItem
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let entry = results["entry"] as? [String: Any]
                else { return nil }
            
            item = NXMyDriveFileItem(withDictionary: entry)
        }
    }
    
    struct DeleteItemResponse: ResponseObjectSerializable {
        var path: String?
        var name: String?
        var usage: Int64
        var quota: Int64
        var myVaultUsage: Int64
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let path = results["pathId"] as? String,
                let name = results["name"] as? String,
                let usage = results["usage"] as? Int64,
                let quota = results["quota"] as? Int64,
                let myVaultUsage = results["myVaultUsage"] as? Int64
            else { return nil }
            
            self.path = path
            self.name = name
            self.usage = usage
            self.quota = quota
            self.myVaultUsage = myVaultUsage
        }
    }
    
    struct SearchResponse: ResponseObjectSerializable {
        var matches: Array<NXMyDriveFileItem>
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let files = results["matches"] as? Array<Dictionary<String, Any>>
                else { return nil }
            
            var arr: Array<NXMyDriveFileItem> = Array()
            for file in files {
                let item = NXMyDriveFileItem(withDictionary: file)
                arr.append(item)
            }
            matches = arr
        }
    }
    
    struct CreatePublicShareURLResponse: ResponseObjectSerializable {
        var url: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let url = results["url"] as? String
                else { return nil }
            
            self.url = url
        }
    }
    
    struct CopyResponse: ResponseObjectSerializable {
        var details: Array<MyDriveDetailFileItem>
        var usage: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let details = results["details"] as? Array<Dictionary<String, Any>>,
                let usage = results["usage"] as? String
                else { return nil }
            
            var arr: Array<MyDriveDetailFileItem> = []
            for file in details {
                let item = MyDriveDetailFileItem(withDictionary: file)
                arr.append(item)
            }
            self.details = arr
            self.usage = usage
        }
    }
    
    struct MoveResponse: ResponseObjectSerializable {
        var details: Array<MyDriveDetailFileItem>
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let details = results["details"] as? Array<Dictionary<String, Any>>
                else { return nil }
            
            var arr: Array<MyDriveDetailFileItem> = []
            for file in details {
                let item = MyDriveDetailFileItem(withDictionary: file)
                arr.append(item)
            }
            self.details = arr
        }
    }
    
    struct GetStorageUsedResponse: ResponseObjectSerializable {
        var usage: Int64?
        var quota: Int64?
        var vaultUsage: Int64?
        var vaultQuota: Int64?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let usage = results["usage"] as? Int64,
                let quota = results["quota"] as? Int64,
                let vaultUsage = results["myVaultUsage"] as? Int64,
                let vaultQuota = results["vaultQuota"] as? Int64
                else { return nil }
            
            self.usage = usage
            self.quota = quota
            self.vaultUsage = vaultUsage
            self.vaultQuota = vaultQuota
        }
    }
}

