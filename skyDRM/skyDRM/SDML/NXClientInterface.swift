//
//  NXSession.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 24/04/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation
import SDML


protocol NXClientDriveInterface {
    // Outbox.
    func getFiles(parentPath: String, completion: @escaping ([NXNXLFile]?, Error?) -> ())
    func deleteFile(file: NXFileBase,isUpload: Bool) -> Error?
    func decryptFile(file: NXNXLFile, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ())
    func reshare(file: NXFileBase, newRecipients: [String], comment: String, completion: @escaping (Error?) -> ())
    func protectFile(type: NXProtectType ,path: String, right: NXRightObligation?, tags: [String: [String]]?, parentFile: SDMLNXLFile?, completion: @escaping (NXNXLFile?, Error?) -> ())

    // MyVault.
    func getFileList(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ())
    func makeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func makeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func viewMyVaultFileOnline(file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String
    func upload(file: NXFileBase, project: NXProjectModel?, progress: ((Double) -> ())?, completion: @escaping (NXFileBase?, Error?) -> ()) -> String
    func cancel(id: String) -> Bool
    func remoteViewRepo(file:NXFileBase,repoId:String?,completion: @escaping (SDMLRemoteViewResult?, Error?) -> ())
    //ShareWithMe
    func getShareWithMeFileList(fromServer:Bool, completion:@escaping([NXSyncFile]?,Error?)->())
    func sharedMakeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func sharedMakeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func viewShareWithMeFileOnline( file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String
    //Project
    func getProjects(fromServer: Bool, completion: @escaping (NXProjectRoot?, Error?) -> ()) -> ()
    func updateProject(project: NXProjectModel, completion: @escaping(NXProjectModel?,Error?) -> ()) -> ()
    func getRightObligationWithTags(totalProject:SDMLProject?, isWorkspace: Bool, tags:[String:[String]],completion:@escaping(NXRightObligation?,Error?)->()) ->()
    func addNXLFileToProject(file: NXNXLFile?, goalProject: SDMLNXLFile, systemFilePath:String?, tags: [String:[String]], completion: @escaping(NXNXLFile?, Error?) -> ()) -> ()
    func viewFileOnlineOfProject(file: NXFileBase,completion: @escaping (NXFileBase?, Error?) -> ()) -> String
    func makeFileOfflineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func makeFileOnlineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> ()
    func remoteViewProject(projectID:String,file:NXFileBase, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ())
    
    func cancelDownload(id: String) -> Bool
    
    // Workspace
    func getWorkspace() -> NXWorkspaceIF?
    
    // Common
    static func getObligationForViewInfo(file:NXSyncFile, completion:@escaping(NXSyncFile?,Error?)->())
    func viewFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String
}

protocol NXClientCommonInterface {
    // Login and loguout.
    func initTenant(router: String, tenantID: String)
    func isLogin() -> Bool
    
//    func loginInView(view: NSView, completion: @escaping (Error?) -> ())
    func loginAsModalWindow(viewController: NSViewController, isPersonal: Bool, completion: @escaping (Error?) -> ())
    func signUp(viewController: NSViewController, completion: @escaping (Error?) -> ())
    func logout(completion: @escaping (Error?) -> ())
    
    // Get session info
    func getUser() -> (NXUser?, Error?)
    func getTenant() -> (NXTenant?, Error?)
    func getUserPreference() -> SDMLUserPreferenceInterface?
    func getTenantPreference() -> SDMLTenantPreferenceInterface?
    func getFullWatermark() -> SDMLWatermark?
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ())
    
    // Log.
    func addLog(file: NXFileBase, log: SDMLActivityLog, completion: @escaping (Error?) -> ())

    // Local.
    func decryptFile(path: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ())
    func getRight(path: String, completion: @escaping ((isOwner: Bool, rights: NXRightObligation, tags: [String: [String]]?)?, Error?) -> ())
    func protectFileToLocal(path: String, right: NXRightObligation?, tags: [String: [String]]?, destPath: String, completion: @escaping (NXNXLFile?, Error?) -> ())
    func remoteViewLocal(path: String, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ())
    func convertFile(path: String, toFormat: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ())
    // get MyVault Repo detail
    func getMyVaultRepoDetail(completion: @escaping (SDMLRepositoryInterface?, Error?) -> ())
    
    //SystemTags
    func getSystemTagModel() -> NXProjectTagTemplateModel?
    
    /// Check is download or upload.
    /// - returns: true if download or upload, false no download and upload.
    func isDownloadOrUpload() -> Bool
    
    func logInViewAfterRouter(view: NSView,cookies:String,urlRequest:URLRequest, isPersonal: Bool, completion: @escaping (Error?) -> ())
    func getUserRouterUrl(completion: @escaping (String?,URLRequest?,Error?) -> ())
    func getLoginRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ())
    func getRegisterURLRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ())
    func setLoginResult(type: Bool, result: String, completion: @escaping (Error?) -> ())
    
    // Helper.
    static func isNXLFile(path: String) -> Bool
    static func getNXLFileInfo(localPath: String) -> NXNXLFile?
    static func checkViewRight(isOwner: Bool, isTag: Bool, right: NXRightObligation, completion: @escaping (Bool?, Error?) -> ())
    static func isExpiry(expiry: NXFileExpiry) -> Bool
    static func isExpiryForever(expiry: NXFileExpiry) -> Bool
}


