//
//  NXLogService.swift
//  skyDRM
//
//  Created by xx-huang on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXLogServiceDelegate: NSObjectProtocol {
    
    @objc optional func getListActivityLogInfoFinished(activityLogInfoModel:[NXActivityLogInfoModel]?,fileName:String?,duid:String?,totalCount:Int,error: Error?)
    @objc optional func putActivityLogInfoFinished(error: Error?)
}

class NXLogService {
    init(userID: String, ticket: String) {
        LogRestAPI.setting(withUserID: userID, ticket: ticket)
    }
    weak var delegate: NXLogServiceDelegate?
    
    //MARK: public Interface
    
    func listActivityLogInfoWith(duid: String,filter:NXActivityLogInfoFilter){
        let parameter: [String: Any] = [RequestParameter.url: ["duid": duid,
                                                               "filter": filter]
        ]
        
        let api = LogRestAPI(type: .getActivityLogInfo)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            
            var fileName, duid:String?
            var totalCount:Int = 0
            var activityLogInfoModels:[NXActivityLogInfoModel]? = []
            if error == nil,
                let responseObject = response as? LogResponse.ListActivityLogInfoResponse {
                totalCount = responseObject.totalCount
                fileName = responseObject.fileName
                duid = responseObject.duid
                activityLogInfoModels = responseObject.activityModel!
            }
            
            guard let delegate = self.delegate,
                delegate.responds(to:#selector(NXLogServiceDelegate.getListActivityLogInfoFinished(activityLogInfoModel:fileName:duid:totalCount:error:))) else {
                    return
            }
            
            delegate.getListActivityLogInfoFinished!(activityLogInfoModel: activityLogInfoModels!, fileName: fileName, duid: duid,totalCount:totalCount,error: error)
        })
    }
    
    
    func putActivityLogInfoWith(activityLogInfoRequestModel:NXPutActivityLogInfoRequestModel){
        let parameter: [String: Any] = [RequestParameter.kParameters:activityLogInfoRequestModel]
        
        let api = LogRestAPI(type: .putActivityLogInfo)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            
            guard let delegate = self.delegate,
                delegate.responds(to:#selector(NXLogServiceDelegate.putActivityLogInfoFinished(error:))) else {
                    return
            }
            
            delegate.putActivityLogInfoFinished!(error: error)
        })
    }
}
