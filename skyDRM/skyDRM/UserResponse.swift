//
//  UserResponse.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/21.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class UserResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = UserRestAPI.UserRestAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .getCaptcha:
            return UserResponse.GetCaptchaResponse(response: response, representation: representation)
        case .resetPassword:
            return UserResponse.ResetPasswordResponse(response: response, representation: representation)
        case .updateProfile:
            return UserResponse.UpdateProfileResponse(response: response, representation: representation)
        case .getProfile:
            return UserResponse.GetProfileResponse(response: response, representation: representation)
        case .changePassword:
            return UserResponse.ChangePasswordResponse(response: response, representation: representation)
        }
    }
    
    struct GetCaptchaResponse: ResponseObjectSerializable {
        var captcha: String!
        var nonce: String!
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else { return nil }
            captcha = results["captcha"] as? String
            nonce = results["nonce"] as? String
        }
    }
    struct UpdateProfileResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
    struct ResetPasswordResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
    struct GetProfileResponse: ResponseObjectSerializable {
        var name: String!
        var email: String!
        var avatar: String!
        init?(response: HTTPURLResponse, representation: Any) {
            if let representation = representation as? [String: Any],
                let extra = representation["extra"] as? [String: Any]  {
                name = extra["name"] as? String
                email = extra["email"] as? String
                if let preferences = extra["preferences"] as? [String: Any],
                    let base64Str = preferences["profile_picture"] as? String,
                    let range = base64Str.range(of: ",", options: String.CompareOptions.backwards, range: nil, locale: nil) {
                    let startIndex = base64Str.index(range.lowerBound, offsetBy: 1)
                    avatar = String(base64Str[startIndex..<base64Str.endIndex])
                    
                }
            }
        }
    }
    struct ChangePasswordResponse: ResponseObjectSerializable {        
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
}
