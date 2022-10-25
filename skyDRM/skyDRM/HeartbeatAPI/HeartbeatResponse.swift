//
//  HeartbeatResponse.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class HeartbeatResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = HeartbeatAPI.HeartbeatAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .getWaterMarkConfig:
            return HeartbeatResponse.getWaterMarkConfigResponse(response: response, representation: representation)
        }
    }
    
    struct getWaterMarkConfigResponse: ResponseObjectSerializable {
        
        var waterMarkContentModel = NXWaterMarkContentModel()
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any]
                else { return nil }
            
            guard
                let results = representation["results"] as? [String: Any],
                let waterMarkConfig = results["watermarkConfig"] as? [String: Any],
                let content = waterMarkConfig["content"] as? String
                else { return }
            
            waterMarkContentModel.serialNumber = waterMarkConfig["serialNumber"] as? String
            
            if content.isEmpty == false{
                
                let contentData = content.data(using: .utf8)
                var contentDic = NSDictionary()
                
                do {
                    contentDic = try (JSONSerialization.jsonObject(with: contentData!, options:
                        .mutableContainers) as? NSDictionary)!
                }
                catch
                {
                    Swift.print("a unexpected error occur: \(error)")
                }
                
                if (contentDic.count) >= 1 {
                    
                    waterMarkContentModel.text = contentDic["text"] as? String
                    waterMarkContentModel.transparentRatio = contentDic["transparentRatio"] as? Int
                    waterMarkContentModel.fontName = contentDic["fontName"] as? String
                    waterMarkContentModel.fontSize = contentDic["fontSize"] as? Int
                    waterMarkContentModel.fontColor = contentDic["fontColor"] as? String
                    
                    if contentDic["rotation"] != nil {
                        let rotationStr:String = (contentDic["rotation"] as? String)!
                        if rotationStr == "Anticlockwise" {
                            waterMarkContentModel.isClockwise = false
                        }
                        else
                        {
                            waterMarkContentModel.isClockwise = true
                        }
                    }
                    waterMarkContentModel.density = contentDic["density"] as? String
                    waterMarkContentModel.isRepeat = contentDic["repeat"] as? Bool
                }
            }
        }
    }
}
