/**
 *
 * for dropbox auth
 *
 */

import Foundation
import SwiftyDropbox

class NXDropboxAuther: NSObject, NXRepoAuthBase, NXServiceOperationDelegate{
    private weak var delegate: NXRepoAuthDelegate?
    private var viewController: NSViewController?
    private var tokenInfo: DropboxAccessToken?
    private var dropboxService: NXDropbox?
    override init() {
        super.init()
    }
    init(viewController: NSViewController) {
        super.init()
        self.viewController = viewController
    }
    init(token: String, uid: String) {
        tokenInfo = DropboxAccessToken(accessToken: token, uid: uid)
    }
    func setDelegate(delegate: NXRepoAuthDelegate) {
        self.delegate = delegate
    }
    
    func authRepo() {
        if !NXCommonUtils.connectedToNetwork() {
            let error = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)!
            DispatchQueue.main.async {
                self.delegate?.authFailed?(error: error)
            }
            return
        }
        if DropboxOAuthManager.sharedOAuthManager == nil {
            DropboxClientsManager.setupWithAppKeyDesktop(DROPBOXKEY)
        }
        guard let viewController = viewController else {
            return
        }
        DropboxClientsManager.authorizeFromController(sharedWorkspace: NSWorkspace.shared(), controller: viewController, openURL: {url in
            if let authResult = DropboxClientsManager.handleRedirectURL(url){
                switch authResult{
                case .success(let tokenInfo):
                    self.tokenInfo = tokenInfo
                    self.dropboxService = NXDropbox(userId: tokenInfo.uid, alias: "", accessToken: tokenInfo.accessToken)
                    self.dropboxService?.setDelegate(delegate: self)
                    _ = self.dropboxService?.getUserInfo()
                case .cancel:
                    DispatchQueue.main.async {
                        self.delegate?.authCanceled?()
                    }
                case .error:
                    let error = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)!
                    DispatchQueue.main.async {
                        self.delegate?.authFailed?(error: error)
                    }
                }
            }
        })
    }

    func removeRepo() {
        if DropboxOAuthManager.sharedOAuthManager == nil {
            DropboxClientsManager.setupWithAppKeyDesktop(DROPBOXKEY)
        }
        guard let tokenInfo = tokenInfo else {
            return
        }
        _ = DropboxOAuthManager.sharedOAuthManager.clearStoredAccessToken(tokenInfo)
        DispatchQueue.main.async {
            self.delegate?.removeFinished?(error: nil)
        }
    }
    
    func reviveRepo() -> Bool {
        return true
    }
    
    func getUserInfoFinished(username: String?, email: String?, totalQuota: NSNumber?, usedQuota: NSNumber?, error: NSError?){
        if let error = error {
            DispatchQueue.main.async {
                self.delegate?.authFailed?(error: error)
            }
        }
        else {
            guard let tokenInfo = tokenInfo else {
                return
            }
            let info = [AUTH_RESULT_ACCOUNT : email, AUTH_RESULT_ACCOUNT_ID : tokenInfo.uid, AUTH_RESULT_ACCOUNT_TOKEN : tokenInfo.accessToken]
            DispatchQueue.main.async {
                self.delegate?.authDidFinished?(authInfo: info)
            }
        }
    }
    func supportCancel() -> Bool {
        return false
    }
    func cancelRepo() {
    }
}
