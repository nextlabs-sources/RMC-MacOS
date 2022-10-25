//
//  NXSharepointOnlineAuther.swift
//  skyDRM
//
//  Created by nextlabs on 03/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSharepointOnlineAuther: NSObject, NXRepoAuthBase, NXSharePointManagerDelegate {
    private weak var delegate: NXRepoAuthDelegate?
    private var keychain = ""
    private var viewController: NSViewController?
    private var token: String?
    private var fedauth = ""
    private var rtfa = ""
    override init() {
        super.init()
    }
    init(token: String) {
        self.token = token
    }
    init(viewController: NSViewController){
        super.init()
        self.viewController = viewController
    }
    func setDelegate(delegate: NXRepoAuthDelegate) {
        self.delegate = delegate
    }
    func authRepo() {
        self.keychain = NXCommonUtils.randomStringwithLength(len: SHAREPOINTONLINEKEYCHAINLENGTH)
        guard let authview  = NXSPAuthViewController(keychain, completion: {sp, user, error in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self.delegate?.authFailed?(error: error)
                }
            }
            else{
                guard let sp = sp,
                    let user = user else {
                        return
                }
                self.fedauth = user.fedauthInfo
                self.rtfa = user.rtfaInfo
                sp.delegate = self
                sp.getCurrentUserInfo()
            }
        }) else {
            Swift.print("failed to create sharepoint online auth view controller")
            return
        }
        viewController?.presentAsModalWindow(authview)
    }
    func removeRepo() {
        guard token != nil else {
            return
        }
        NXSPAuthViewController.remove(fromKeyChain: token)
        DispatchQueue.main.async {
            self.delegate?.removeFinished?(error: nil)
        }
    }
    func reviveRepo() -> Bool {
        guard let token = token,
        let property = NXCommonUtils.parseSharepointOnlineToken(token: token),
        let keychain = property["keychainName"] as? String,
        let url = property["url"] as? String,
        let fedAuth = property["fedAuth"] as? String,
        let rtfa = property["rtFa"] as? String else {
            return false
        }
        NXSPAuthViewController.saveAuth(toKeyChain: keychain, url: url, fedAuth: fedAuth, rtfa: rtfa)
        return true
    }
    func getUserInfoFinished(withEmail email: String!, url: String!, totalstorage: Int64, usedstorage: Int64, error: Error!) {
        if let error = error as NSError?{
            DispatchQueue.main.async {
                self.delegate?.authFailed?(error: error)
            }
        }
        else{
            if let token = NXCommonUtils.combineSharepointOnlineToken(keychainName: keychain, url: url, fedAuth: fedauth, rtFa: rtfa) {
                
                let info = [AUTH_RESULT_ACCOUNT : email, AUTH_RESULT_ACCOUNT_ID : url, AUTH_RESULT_ACCOUNT_TOKEN : token]
                DispatchQueue.main.async {
                    self.delegate?.authDidFinished?(authInfo: info as [String : Any] )
                }
            }
        }
    }
    func supportCancel() -> Bool {
        return false
    }
    func cancelRepo() {
    }
    
}
