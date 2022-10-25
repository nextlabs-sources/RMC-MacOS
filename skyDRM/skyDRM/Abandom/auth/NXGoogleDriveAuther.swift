//
//  NXGoogleDriveAuther.swift
//  skyDRM
//
//  Created by nextlabs on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXGoogleDriveAuther: NSObject, NXRepoAuthBase {
    private weak var delegate: NXRepoAuthDelegate?
    private var token: String?
    private let successURLString = "http://openid.github.io/AppAuth-iOS/redirect/"
    private var redirectHttpHandler: OIDRedirectHTTPHandler!
    override init() {
    }
    init(token: String) {
        self.token = token
    }
    func setDelegate(delegate: NXRepoAuthDelegate) {
        self.delegate = delegate
    }
    func authRepo() {
        let authError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)!
        let successURL = URL(string: successURLString)
        redirectHttpHandler = OIDRedirectHTTPHandler(successURL: successURL)
        var error: NSError?
        let localURI = redirectHttpHandler.startHTTPListener(&error)
        guard error == nil else {
            DispatchQueue.main.async {
                self.delegate?.authFailed?(error: authError)
            }
            return
        }
        
        let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()
        let request = OIDAuthorizationRequest(configuration: configuration, clientId: GOOGLEDRIVECLIENTID, clientSecret: GOOGLEDRIVECLIENTSECRET, scopes: [kGTLRAuthScopeDrive, OIDScopeEmail], redirectURL: localURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
        redirectHttpHandler.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, callback: {[weak self] state, error in
            if let error = error as? NSError {
                if error.code == -4 {
                    DispatchQueue.main.async {
                        self?.delegate?.authCanceled?()
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self?.delegate?.authFailed?(error: error)
                    }
                }
            }
            else{
                guard let state = state else {
                    DispatchQueue.main.async {
                        self?.delegate?.authFailed?(error: authError)
                    }
                    return
                }
                let gtmAuthorization = GTMAppAuthFetcherAuthorization(authState: state)
                let keychain = NXCommonUtils.randomStringwithLength(len: GOOGLEDRIVEKEYCHAINITEMLENGTH)
                GTMAppAuthFetcherAuthorization.save(gtmAuthorization, toKeychainForName: keychain)
//                let persistenceResponseString = "undefinedPersistenceString"
//                let token = NXCommonUtils.combineGoogleDriveToken(keychainName: keychain, persistenceString: persistenceResponseString)
                if let email = gtmAuthorization.userEmail, let userId = gtmAuthorization.userID {
                    let info = [AUTH_RESULT_ACCOUNT: email, AUTH_RESULT_ACCOUNT_ID: userId, AUTH_RESULT_ACCOUNT_TOKEN : keychain]
                    DispatchQueue.main.async {
                        self?.delegate?.authDidFinished?(authInfo: info)
                    }
                }
            }
        })
    }
    
    func removeRepo() {
        guard let token = token else {
            return
        }
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: token)
        DispatchQueue.main.async {
            self.delegate?.removeFinished?(error: nil)
        }
    }
    func reviveRepo() -> Bool {
//        guard let token = token,
//            let property = NXCommonUtils.parseGoogleDriveToken(token: token),
//            let keychain = property["keychainName"] as? String,
//            let persistenceString = property["persistenceString"] as? String else {
//                return false
//        }
//        
//        let auth = GTMOAuth2Authentication()
//        auth.setKeysForPersistenceResponseString(persistenceString)
//        GTMOAuth2WindowController.saveAuthToKeychain(forName: keychain, authentication: auth)
        return false
    }
    func supportCancel() -> Bool {
        return true
    }
    func cancelRepo() {
        redirectHttpHandler.cancelHTTPListener()
    }
}
