//
//  NXUserRestProvider.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/21.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXUserServiceDelegate: NSObjectProtocol {
    @objc optional func getCaptchaFinished(captcha: String?, nonce: String?, error: Error?)
    @objc optional func resetPasswordFinished(error: Error?)
    @objc optional func updateAvatarFinished(error: Error?)
    @objc optional func updateDisplayNameFinished(error: Error?)
    @objc optional func getProfileFinished(name: String?, email: String?, avatar: String?, error: Error?)
    @objc optional func changePasswordFinished(error: Error?)
    @objc optional func getServerLoginURLFinished(loginURL: String?,error: Error?)
}

class NXUserService {
    init(userID: String, ticket: String) {
        UserRestAPI.setting(withUserID: userID, ticket: ticket)
    }
    weak var delegate: NXUserServiceDelegate?
    
    //MARK: public Interface
    func getCaptcha(){
        let api = UserRestAPI(type: .getCaptcha)
        api.sendRequest(withParameters: nil, completion: {response, error in
            var captcha, nonce: String?
            if error == nil,
                let responseObject = response as? UserResponse.GetCaptchaResponse {
                captcha = responseObject.captcha
                nonce = responseObject.nonce
            }
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.getCaptchaFinished(captcha:nonce:error:))) else {
                return
            }
            delegate.getCaptchaFinished!(captcha: captcha, nonce: nonce, error: error)
        })
    }
    func resetPassword(captcha: String, nonce: String){
        let email = NXLoginUser.sharedInstance.nxlClient?.profile.email
        let parameter = "email=\(String(describing: email))nonce=\(nonce)captcha=\(captcha)"
        let api = UserRestAPI(type: .resetPassword)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.resetPasswordFinished(error:))) else {
                return
            }
            delegate.resetPasswordFinished!(error: error)
        })
    }
    func updateAvatar(avatar: String) {
        let parameter = ["preferences": ["profile_picture": "data:image/jpeg;base64,\(avatar)"]] as [String : Any]
        let api = UserRestAPI(type: .updateProfile)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.updateAvatarFinished(error:))) else {
                    return
            }
            delegate.updateAvatarFinished!(error: error)
        })
    }
    func updateDisplayName(displayName: String){
        let parameter = ["displayName": displayName] as [String : Any]
        let api = UserRestAPI(type: .updateProfile)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.updateDisplayNameFinished(error:))) else {
                    return
            }
            delegate.updateDisplayNameFinished!(error: error)
        })
    }
    func getProfile() {
        let api = UserRestAPI(type: .getProfile)
        api.sendRequest(withParameters: nil, completion: {response, error in
            var name, email, avatar: String?
            if error == nil,
                let responseObject = response as? UserResponse.GetProfileResponse {
                name = responseObject.name
                email = responseObject.email
                avatar = responseObject.avatar
            }
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.getProfileFinished(name:email:avatar:error:))) else {
                    return
            }
            delegate.getProfileFinished!(name: name, email: email, avatar: avatar, error: error)
        })
    }
    func changePassword(old: String, new: String) {
        let oldMd5 = (old as NSString).md5() as String
        let newMd5 = (new as NSString).md5() as String
        let parameter = ["oldPassword": oldMd5, "newPassword": newMd5] as [String : Any]
        let api = UserRestAPI(type: .changePassword)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.changePasswordFinished(error:))) else {
                    return
            }
            delegate.changePasswordFinished!(error: error)
        })
    }
    
    func getServerLoginURL(userInputedURL: String) {
     
        hostURLString = userInputedURL;
        let api = RouterLoginURLAPI(type: .getServerLoginURL)
        api.sendRequest(withParameters: nil, completion: {response, error in
            
            var loginURL: String?
            if error == nil,
                let responseObject = response as? RouterLoginURLResponse.GetServerLoginURLInfoResponse  {
                loginURL = responseObject.serverReturnLoginURL
            }
            
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXUserServiceDelegate.getServerLoginURLFinished(loginURL:error:))) else {
                    return
            }
            delegate.getServerLoginURLFinished!(loginURL: loginURL, error: error)
        })
    }
}
