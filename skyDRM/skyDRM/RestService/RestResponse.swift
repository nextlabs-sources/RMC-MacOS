//
//  RestResponse.swift
//  skyDRM
//
//  Created by pchen on 07/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

typealias ResponseHandler = (HTTPURLResponse?, Any?, Error?) -> Void

protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
}

struct ResponseHeader {
    static let kContentDisposition = "Content-Disposition"
    
}

class RestResponse {
    
    init(responseType: Int, completion: @escaping CallBack) {
        
        var temp: RestResponse? = self
        self.handler = {
            
            response, result, error in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response, let result = result else {
                completion(nil, BackendError.failResponse(reason: "response or result is nil"))
             
                return
            }
            
            guard response.statusCode >= 200 && response.statusCode < 300 else {
                completion(nil, BackendError.failResponse(reason: "error code: \(response.statusCode)"))
                return
            }
            
            let representation: Any = {
                if result is [String: Any] {
                    return result
                } else if result is Data {
                    if let json = try? JSONSerialization.jsonObject(with: result as! Data, options: .allowFragments),
                        let jsonDic = json as? [String: Any] {
                        return jsonDic
                    } else {
                        return result
                    }
                } else {
                    return result
                }
            }()
            
            if let jsonDic = representation as? [String: Any],
                let statusCode = jsonDic["statusCode"] as? Int,
                let message = jsonDic["message"] as? String {
                if statusCode == 401 {
                    let NotifySkyDRMTokenExpired = NSNotification.Name(rawValue:SKYDRM_TOKEN_EXPIRED)
                    NotificationCenter.default.post(name:NotifySkyDRMTokenExpired, object: nil, userInfo: nil)
                    return
                }
                
                guard statusCode >= 200 && statusCode < 300 else {
                    
                    if statusCode == 404 {
                        completion(nil, BackendError.notFound)
                    } else if statusCode == 304 {
                        completion(nil, BackendError.notModified)
                    } else {
                        completion(nil, BackendError.failResponse(reason: message))
                    }
                    
                    return
                }
            }
            
            let object = temp?.responeObject(responseType: responseType, response: response, representation: representation)
            temp = nil
            
            guard let nonilObject = object else {
                completion(nil, BackendError.failResponse(reason: "result cannot response to object: \(result)"))
                return
            }
            
            completion(nonilObject, nil)
            return
        }
    }
    
    var handler: ResponseHandler?
    
    func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        return nil
    }
}
