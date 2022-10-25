//
//  NXHeartbeatService.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXHeartbeatServiceDelegate: NSObjectProtocol {
    
    @objc optional func getWaterMarkConfigFinished(waterMarkConfigModel:NXWaterMarkContentModel?,error: Error?)
}

class NXHeartbeatService {
    init(userID: String, ticket: String) {
        HeartbeatAPI.setting(withUserID: userID, ticket: ticket)
    }
    weak var delegate: NXHeartbeatServiceDelegate?
    
    //MARK: public Interface
    
    func getWaterMarkConfigInfoWith(platformId: Int){
        let parameter: [String: Any] = [RequestParameter.body: ["platformId": platformId]
        ]
        
        let api = HeartbeatAPI(type: .getWaterMarkConfig)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            
            var waterMarkConfigModel:NXWaterMarkContentModel?
            if error == nil,
                let responseObject = response as? HeartbeatResponse.getWaterMarkConfigResponse {
                waterMarkConfigModel = responseObject.waterMarkContentModel
            }
            
            guard let delegate = self.delegate,
                delegate.responds(to:#selector(NXHeartbeatServiceDelegate.getWaterMarkConfigFinished(waterMarkConfigModel:error:))) else {
                    return
            }
            
            delegate.getWaterMarkConfigFinished!(waterMarkConfigModel: waterMarkConfigModel, error: error)
        })
    }
}
