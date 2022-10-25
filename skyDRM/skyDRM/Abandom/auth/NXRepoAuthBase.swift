//
//  NXRepoAuthBase.swift
//  skyDRM
//
//  Created by nextlabs on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
let AUTH_RESULT_ACCOUNT  = "AUTH_RESULT_ACCOUNT"
let AUTH_RESULT_ACCOUNT_ID = "AUTH_RESULT_ACCOUNT_ID"
let AUTH_RESULT_ACCOUNT_TOKEN = "AUTH_RESULT_ACCOUNT_TOKEN"

@objc protocol NXRepoAuthDelegate: NSObjectProtocol{
    @objc optional func authDidFinished(authInfo: [String: Any])
    @objc optional func authFailed(error: NSError)
    @objc optional func authCanceled()
    @objc optional func removeFinished(error: NSError?)
}

@objc protocol NXRepoAuthBase: NSObjectProtocol{
    func authRepo()
    func removeRepo()
    func reviveRepo() -> Bool
    func setDelegate(delegate: NXRepoAuthDelegate)
    func supportCancel() -> Bool
    func cancelRepo()
}
