//
//  LogResponse.swift
//  skyDRM
//
//  Created by xx-huang on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class LogResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = LogRestAPI.LogRestAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .getActivityLogInfo:
            return LogResponse.ListActivityLogInfoResponse(response: response, representation: representation)
            
        case .putActivityLogInfo:
            return LogResponse.putActivityLogInfoResponse(response: response, representation: representation)
        }
    }
    
    struct ListActivityLogInfoResponse: ResponseObjectSerializable {
        var totalCount: Int = 0
        var fileName: String?
        var duid: String?
        var activityModel: [NXActivityLogInfoModel]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any]
                else { return nil }
            
            guard
                let results = representation["results"] as? [String: Any],
                let data = results["data"] as? [String: Any],
                let fileName = data["name"] as? String,
                let duid = data["duid"] as? String,
                let totalCount = results["totalCount"] as? Int,
                let logRecordsDic = data["logRecords"] as? [[String: Any]]
                else { return }
            
            self.totalCount = totalCount
            self.fileName = fileName
            self.duid = duid
            
            activityModel = [NXActivityLogInfoModel]()
            for dic in logRecordsDic {
                let activityLogInfoModel = NXActivityLogInfoModel(withDictionary: dic)
                activityModel?.append(activityLogInfoModel)
            }
        }
    }
    
    struct putActivityLogInfoResponse: ResponseObjectSerializable {
        
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
}
