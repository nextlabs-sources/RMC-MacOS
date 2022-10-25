//
//  NXOneDriveAuther.swift
//  skyDRM
//
//  Created by nextlabs on 12/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXOneDriveAuther: NSObject, NXRepoAuthBase {
    private weak var delegate: NXRepoAuthDelegate?
    private var viewController: NSViewController?
    override init() {
        super.init()
    }
    init(viewController: NSViewController){
        super.init()
        self.viewController = viewController
    }
    func setDelegate(delegate: NXRepoAuthDelegate) {
        self.delegate = delegate
    }
    func authRepo() {
        ODClient.setMicrosoftAccountAppId(ONEDRIVECLIENTID, scopes: ONEDRIVESCOPE)
        ODClient.setParentAuthController(viewController)
        ODClient.authenticatedClient(completion: {client, error in
            if let error = error as? NSError {
                DispatchQueue.main.async {
                    self.delegate?.authFailed?(error: error)
                }
            }
            else{
                _ = client?.drive().request().getWithCompletion({drive, driveError in
                    if let driveError = driveError as? NSError {
                        DispatchQueue.main.async {
                            self.delegate?.authFailed?(error: driveError)
                        }
                    }
                    else if let displayName = drive?.owner.user.displayName,
                        let id = drive?.owner.user.id {
                        //                        var account = ""
                        var token = ""
                        //                        var id = ""
                        if let accountSession = client?.authProvider.accountSession?(),
                            //                            let accountId = client?.accountId,
                            //                            let userEmail = accountSession.serviceInfo.userEmail,
                            let accessToken = accountSession.accessToken {
                            //                            id = accountId
                            ODAccountStore.default().storeCurrentAccount(accountSession)
                            //                            account = userEmail
                            token = accessToken
                        }
                        DispatchQueue.main.async {
                            let info = [AUTH_RESULT_ACCOUNT : displayName, AUTH_RESULT_ACCOUNT_ID : id, AUTH_RESULT_ACCOUNT_TOKEN : token] as [String : Any]
                            self.delegate?.authDidFinished?(authInfo: info)
                        }
                    }
                })
            }
        })
    }
    func removeRepo() {
        NXCommonUtils.saveOnedriveState(bExisted: false)
        ODClient.setMicrosoftAccountAppId(ONEDRIVECLIENTID, scopes: ONEDRIVESCOPE)
        if let client = ODClient.loadCurrent() {
            client.signOut(completion: {error in
                DispatchQueue.main.async {
                    self.delegate?.removeFinished?(error: error as NSError?)
                }
            })
        }
        else {
            DispatchQueue.main.async {
                let error = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: nil)
                self.delegate?.removeFinished?(error: error)
            }
        }
    }
    func reviveRepo() -> Bool {
        return false
    }
    func supportCancel() -> Bool {
        return false
    }
    func cancelRepo(){
    }
}
