//
//  NXClientService.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/24/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXClientService {
    fileprivate struct Constant {
        static let sessionID = "com.nxrmc.skyDRM"
        static let loginNibName = "NXLoginViewController"
    }
    
    init() {
        session = createInstance(identifier: Constant.sessionID).value!
    }
    
    var session: SDMLSessionInterface
    
    var flage = false
    
    var workspace: NXWorkspaceIF?
}

// MARK: Login.

extension NXClientService: NXClientCommonInterface {
    func initTenant(router: String, tenantID: String) {
        guard let manager = session.getLoginManager().value else {
            return
        }
        
        manager.initTenant(router: router, tenantId: tenantID)
    }
    
    func isLogin() -> Bool {
        guard let manager = session.getLoginManager().value else {
            return false
        }
        return manager.isLogin()
    }
    
    func getTenant() -> (NXTenant?, Error?) {
        if let libTenant = session.getCurrentTenant().value {
            let tenant = NXTenant(tenantID: libTenant.getTenant(), routerURL: libTenant.getRouterURL(), rmsURL: libTenant.getRMSURL())
            return (tenant, nil)
        }
        
        return (nil, session.getCurrentTenant().error!)
    }
    
    func getUserRouterUrl(completion: @escaping (String?,URLRequest?,Error?) -> ()) {
        getServerLoginUrl(completion: completion)
    }
    
    func logInViewAfterRouter(view: NSView,cookies:String,urlRequest:URLRequest, isPersonal: Bool, completion: @escaping (Error?) -> ()) {
        // Display login view.
        let loginVC = NXLoginViewController(nibName: Constant.loginNibName, bundle: nil)
        view.addSubview(loginVC.view)
        
        loginVC.loginAfterRouter(type: isPersonal, cookie: cookies, request: urlRequest) { error in
            loginVC.unbind()
            completion(error)
        }
    }
    
    func loginAsModalWindow(viewController: NSViewController, isPersonal: Bool, completion: @escaping (Error?) -> ()) {
        // Display login view as model window.
        let loginVC = NXLoginViewController(nibName:Constant.loginNibName, bundle: nil)
        viewController.presentAsModalWindow(loginVC)
        
        loginVC.login(type: isPersonal) { error in
            loginVC.unbind()
            viewController.dismiss(loginVC)
            
            // FIX Bug: Two model window can not dimiss at once.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(error)
            }
            
        }
    }
    
    func signUp(viewController: NSViewController, completion: @escaping (Error?) -> ()) {
        // Display login view as model window.
        let loginVC = NXLoginViewController(nibName:Constant.loginNibName, bundle: nil)
        viewController.presentAsModalWindow(loginVC)
        
        loginVC.register() { error in
            loginVC.unbind()
            viewController.dismiss(loginVC)
            
            completion(error)
        }
    }
    
    func getLoginRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ()) {
        let manager = (session.getLoginManager().value)!
        manager.getLoginURLRequest { result in
            completion(result.value, result.error)
        }
    }
    
    func getRegisterURLRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ()) {
        let manager = (session.getLoginManager().value)!
        manager.getRegisterURLRequest { result in
            completion(result.value, result.error)
        }
    }
    
    func setLoginResult(type: Bool, result: String, completion: @escaping (Error?) -> ()) {
        let manager = (session.getLoginManager().value)!
        manager.setLoginResult(response: result, isPersonal: type, completion: { (result) in
            completion(result.error)
        })
    }
    
    func getUser() -> (NXUser?, Error?) {
        let result = session.getCurrentUser()
        if let libUser = result.value {
            let user = NXUser(name: libUser.getName(), userID: libUser.getUserID(), email: libUser.getEmail(), userIdpType: Int(libUser.getUserIdpType()?.rawValue ?? 0), isPersonal: libUser.getIsPersonal())
            return (user, nil)
        }
        
        return (nil, result.error!)
    }
    
    func logout(completion: @escaping (Error?) -> ()) {
        let manager = (session.getLoginManager().value)!
        manager.logout { (result) in
            if result.error == nil {
                // Replace a new session
                self.session = createInstance(identifier: Constant.sessionID).value!
            }
            
            completion(result.error)
        }
    }
}

// MARK: Other.

extension NXClientService {
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ()) {
        let service = session.getMyVaultManager().value
        service?.getStorage(completion: { (result) in
            completion(result.value, result.error)
        })
    }
    
    func getSystemTagModel() -> NXProjectTagTemplateModel? {
        let manager = session.getSystemTagPolicyManager()
        guard let service = manager.value else {
            return nil
        }
        let tagModel = NXProjectTagTemplateModel()
        if let sdmlTagModel = service.getSystemPolicyTagModel() {
            NXCommonUtils.transform(from: sdmlTagModel, to: tagModel)
        }
        
        return tagModel
    }
    
    func addLog(file: NXFileBase, log: SDMLActivityLog, completion: @escaping (Error?) -> ()) {
        let manageResult = session.getLogManager()
        guard let service = manageResult.value else {
            completion(manageResult.error)
            return
        }
        
        if file.sdmlBaseFile != nil {
            service.addLog(file: file.sdmlBaseFile as! SDMLNXLFile, log: log) { (result) in completion(result.error) }
        } else {
            service.addLog(path: file.localPath, log: log) { (result) in completion(result.error) }
        }
    }
    
    func getUserPreference() -> SDMLUserPreferenceInterface? {
        return session.getUserPreference().value
    }
    
    func getTenantPreference() -> SDMLTenantPreferenceInterface? {
        return session.getTenantPreference().value
    }
    
    func getFullWatermark() -> SDMLWatermark? {
        return session.getFullWatermark().value
    }
    
    func getMyVaultRepoDetail(completion: @escaping (SDMLRepositoryInterface?, Error?) -> ())
    {
        let result = session.getRepoManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        
        _ = manager.getRepositories(completion: { (result) in
            guard let repos = result.value else {
                completion(nil, result.error)
                return
            }
            
            let myDrive = repos.filter() { $0.getName() == "MyDrive" }
            completion(myDrive.first, nil)
        })
    }
    
    func decryptFile(path: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        let result = session.getNXLFileManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        
        manager.decryptFile(path: path, toFolder: toFolder, isOverwrite: isOverwrite) { (result) in
            completion(result.value, result.error)
        }
    }
    
    func getRight(path: String, completion: @escaping ((isOwner: Bool, rights: NXRightObligation, tags: [String: [String]]?)?, Error?) -> ()) {
        
        let result = session.getNXLFileManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        manager.getRight(path: path) { (result) in
            if let error = result.error {
                completion(nil, error)
                return
            }
            let obRights = NXRightObligation()
            if let rights = result.value!.rights {
                // Transform rights.
                NXCommonUtils.transform(from: rights, to: obRights)
            }
            completion((result.value!.isOwner, obRights, result.value?.tags), nil)
        }
    }
    
    func remoteViewLocal(path: String, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        let result = session.getRemoteViewManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        
        _ = manager.viewLocal(path: path, progress: nil) { (result) in
            completion(result.value, result.error)
        }
    }
    
    func convertFile(path: String, toFormat: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        let result = session.getConvertFileManager()
        guard let manager = result.value else {
            completion(nil, result.error)
            return
        }
        _ = manager.convert(path: path, toFormat: toFormat, toFolder: toFolder, isOverwrite: isOverwrite, progress: nil) { (result) in
            completion(result.value, result.error)
        }
    }
    
    static func isNXLFile(path: String) -> Bool {
        return SDMLHelper.isNXLFile(path: path)
    }
    
    static func getNXLFileInfo(localPath: String) -> NXNXLFile? {
        if let sdmlFile = SDMLHelper.getNXLFileInfo(localPath: localPath) {
            let nxlFile = NXNXLFile()
            NXCommonUtils.transform(from: sdmlFile, to: nxlFile)
            return nxlFile
        }
        
        return nil
        
    }
    
    static func checkViewRight(isOwner: Bool, isTag: Bool, right: NXRightObligation, completion: @escaping (Bool?, Error?) -> ()) {
        var sdmlRight: SDMLRightObligation?
        NXCommonUtils.transform(from: right, to: &sdmlRight)
        
        SDMLHelper.checkViewRight(isOwner: isOwner, isTag: isTag, right: sdmlRight!) { (result) in
            completion(result.value, result.error)
        }
    }
    func protectFileToLocal(path: String, right: NXRightObligation?, tags: [String: [String]]?, destPath: String, completion: @escaping (NXNXLFile?, Error?) -> ()) {
        let manager = session.getProtectManager().value
        var sdmlRights: SDMLRightObligation?
        if right != nil {
            NXCommonUtils.transform(from: right!, to: &sdmlRights)
        }
        manager?.protectOriginFileToLocal(destPath: destPath, path: path, rights: (right != nil ? sdmlRights : nil), tags: (right != nil ? nil : tags), completion: { (result) in
            if let error = result.error {
                completion(nil, error)
                return
            }
            
            let file = NXNXLFile()
            file.localFile = true
            file.status?.status = .waiting
            NXCommonUtils.transform(from: result.value!, to: file)
            completion(file, nil)
        })
    }
    
    func isDownloadOrUpload() -> Bool {
        var result = false
        let uploadManager = session.getUploadManager().value!
        let downloadManager = session.getDownloadManager().value!
        if uploadManager.getOperationCount() > 0 || downloadManager.getOperationCount() > 0 {
            result = true
        }
        
        return result
    }
    
    static func isExpiry(expiry: NXFileExpiry) -> Bool {
        var sdmlExpiry: SDMLExpiry?
        NXCommonUtils.transform(from: expiry, to: &sdmlExpiry)
        return SDMLHelper.isExpiry(expiry: sdmlExpiry!)
    }
    
    static func isExpiryForever(expiry: NXFileExpiry) -> Bool {
        var sdmlExpiry: SDMLExpiry?
        NXCommonUtils.transform(from: expiry, to: &sdmlExpiry)
        return SDMLHelper.isExpiryForever(expiry: sdmlExpiry!)
    }
}

// MARK: Private methods.

extension NXClientService {
    fileprivate func getServerLoginUrl(completion: @escaping (String?,URLRequest?,Error?) -> ()){
        let manager = (session.getLoginManager().value)!
        manager.getLoginURLRequest { (result) in
            if let error = result.error {
                completion("",nil,error)
                return
            }
            let loginInfo = result.value!
            completion(loginInfo.0,loginInfo.1,nil)
            return
        }
    }
    
}


