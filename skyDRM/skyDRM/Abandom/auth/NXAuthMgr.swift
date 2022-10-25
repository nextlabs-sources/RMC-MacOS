//
//  NXAuthMgr.swift
//  skyDRM
//
//  Created by nextlabs on 2017/3/21.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXAuthMgrDelegate: NSObjectProtocol {
    func addFinished(repo: NXRMCRepoItem?, error: NSError?)
}

class NXAuthMgr: NSObject, NXRepoAuthDelegate {
    static let shared = NXAuthMgr()
    private override init() {}
    weak var delegate: NXAuthMgrDelegate?
    private var currentRepo: NXRMCRepoItem?
    private var auth: NXRepoAuthBase?
    
    func add(item: NXRMCRepoItem, window: NSWindow) {
        currentRepo = item.copy() as? NXRMCRepoItem
        guard let vc = window.contentViewController else {
            return
        }
        switch item.type {
        case .kServiceSharepointOnline:
            auth = NXSharepointOnlineAuther(viewController: vc)
        default:
            break
        }
        if let auth = auth {
            auth.setDelegate(delegate: self)
            auth.authRepo()
        }
    }
    
    func remove(item: NXRMCRepoItem) {
        switch item.type {
        case .kServiceSharepointOnline:
            auth = NXSharepointOnlineAuther(token: item.token)
        
        default:
            break
        }
        if let auth = auth {
            auth.removeRepo()
        }
    }
    func supportCancel() -> Bool {
        guard let auth = auth else {
            return false
        }
        return auth.supportCancel()
    }
    func cancel() {
        auth?.cancelRepo()
    }
    
    //MARK: NXRepoAuthDelegate
    func authDidFinished(authInfo: [String: Any]) {
        guard let accountName = authInfo[AUTH_RESULT_ACCOUNT] as? String,
            let accountId = authInfo[AUTH_RESULT_ACCOUNT_ID] as? String,
            let token = authInfo[AUTH_RESULT_ACCOUNT_TOKEN] as? String else {
                let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)
                delegate?.addFinished(repo: nil, error: retError)
                return
        }
        
        let retRepo = NXRMCRepoItem()
        guard let currentRepo = self.currentRepo else {
            return
        }
        retRepo.type = currentRepo.type
        retRepo.name = currentRepo.name
        retRepo.token = token
        retRepo.accountName = accountName
        retRepo.accountId = accountId
        
        retRepo.repoId = currentRepo.repoId
        
        delegate?.addFinished(repo: retRepo, error: nil)
    }
    
    func authCanceled() {
        let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)
        delegate?.addFinished(repo: nil, error: retError)
    }
    func authFailed(error: NSError) {
        delegate?.addFinished(repo: nil, error: error)
    }

}

