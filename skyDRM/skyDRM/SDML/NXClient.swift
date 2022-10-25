//
//  NXClient.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 31/05/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXClient {
    
    static let sharedInstance = NXClient()
    static func getCurrentClient() -> NXClient {
        return sharedInstance
    }
    init() {
        let service = NXClientService()
        common = service
        drive = NXClientCacheDrive(drive: service)
        session = service.session
    }
    
    
    let common: NXClientCommonInterface
    let drive: NXClientDriveInterface
    let session: SDMLSessionInterface
}



extension NXClient: NXClientCommonInterface {
    func initTenant(router: String, tenantID: String) {
        common.initTenant(router: router, tenantID: tenantID)
    }
    func isLogin() -> Bool {
        return common.isLogin()
    }
    
    func loginAsModalWindow(viewController: NSViewController, isPersonal: Bool, completion: @escaping (Error?) -> ()) {
        common.loginAsModalWindow(viewController: viewController, isPersonal: isPersonal, completion: completion)
    }
    
    func signUp(viewController: NSViewController, completion: @escaping (Error?) -> ()) {
        common.signUp(viewController: viewController, completion: completion)
    }
    
    func logout(completion: @escaping (Error?) -> ()) {
        common.logout(completion: completion)
    }
    
    func getUser() -> (NXUser?, Error?) {
        return common.getUser()
    }
    
    func getTenant() -> (NXTenant?, Error?) {
        return common.getTenant()
    }
    
    func getUserPreference() -> SDMLUserPreferenceInterface? {
        return common.getUserPreference()
    }
    
    func getTenantPreference() -> SDMLTenantPreferenceInterface? {
        return common.getTenantPreference()
    }
    
    func getFullWatermark() -> SDMLWatermark? {
        return common.getFullWatermark()
    }
    
    func getStorage(completion: @escaping ((usage: UInt, quota: UInt)?, Error?) -> ()) {
        common.getStorage(completion: completion)
    }
    
    // Log.
    func addLog(file: NXFileBase, log: SDMLActivityLog, completion: @escaping (Error?) -> ()) {
        common.addLog(file: file, log: log, completion: completion)
    }
    
    // Local.
    func decryptFile(path: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        common.decryptFile(path: path, toFolder: toFolder, isOverwrite: isOverwrite, completion: completion)
    }
    
    func getRight(path: String, completion: @escaping ((isOwner: Bool, rights: NXRightObligation, tags: [String: [String]]?)?, Error?) -> ()) {
        common.getRight(path: path, completion: completion)
    }
    
    func protectFileToLocal(path: String, right: NXRightObligation?, tags: [String: [String]]?, destPath: String, completion: @escaping (NXNXLFile?, Error?) -> ()) {
        common.protectFileToLocal(path: path, right: right, tags: tags, destPath: destPath, completion: completion)
    }
    
    func remoteViewLocal(path: String, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        common.remoteViewLocal(path: path, completion: completion)
    }
    
    func convertFile(path: String, toFormat: String, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        common.convertFile(path: path, toFormat: toFormat, toFolder: toFolder, isOverwrite: isOverwrite, completion: completion)
    }
    
    // get MyVault Repo detail
    func getMyVaultRepoDetail(completion: @escaping (SDMLRepositoryInterface?, Error?) -> ()) {
        common.getMyVaultRepoDetail(completion: completion)
    }
    
    //SystemTags
    func getSystemTagModel() -> NXProjectTagTemplateModel? {
        return common.getSystemTagModel()
    }
    
    /// Check is download or upload.
    /// - returns: true if download or upload, false no download and upload.
    func isDownloadOrUpload() -> Bool {
        return common.isDownloadOrUpload()
    }
    
    func logInViewAfterRouter(view: NSView,cookies:String,urlRequest:URLRequest, isPersonal: Bool, completion: @escaping (Error?) -> ()) {
        common.logInViewAfterRouter(view: view, cookies: cookies, urlRequest: urlRequest, isPersonal: isPersonal, completion: completion)
    }
    
    func getUserRouterUrl(completion: @escaping (String?,URLRequest?,Error?) -> ()) {
        common.getUserRouterUrl(completion: completion)
    }
    
    func getLoginRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ()) {
        common.getLoginRequest(completion: completion)
    }
    
    func getRegisterURLRequest(completion: @escaping ((String, URLRequest)?, Error?) -> ()) {
        common.getRegisterURLRequest(completion: completion)
    }
    
    func setLoginResult(type: Bool, result: String, completion: @escaping (Error?) -> ()) {
        common.setLoginResult(type: type, result: result, completion: completion)
    }
    
    // Helper.
    static func isNXLFile(path: String) -> Bool {
        return NXClientService.isNXLFile(path: path)
    }
    
    static func getNXLFileInfo(localPath: String) -> NXNXLFile? {
        return NXClientService.getNXLFileInfo(localPath: localPath)
    }
    
    static func checkViewRight(isOwner: Bool, isTag: Bool, right: NXRightObligation, completion: @escaping (Bool?, Error?) -> ()) {
        NXClientService.checkViewRight(isOwner: isOwner, isTag: isTag, right: right, completion: completion)
    }
    
    static func isExpiry(expiry: NXFileExpiry) -> Bool {
        return NXClientService.isExpiry(expiry: expiry)
    }
    
    static func isExpiryForever(expiry: NXFileExpiry) -> Bool {
        return NXClientService.isExpiryForever(expiry: expiry)
    }
    
}

extension NXClient: NXClientDriveInterface {
    // Outbox.
    func getFiles(parentPath: String, completion: @escaping ([NXNXLFile]?, Error?) -> ()) {
        drive.getFiles(parentPath: parentPath, completion: completion)
    }
    
    func deleteFile(file: NXFileBase,isUpload: Bool) -> Error? {
        return drive.deleteFile(file: file, isUpload: isUpload)
    }
    func decryptFile(file: NXNXLFile, toFolder: String, isOverwrite: Bool, completion: @escaping (String?, Error?) -> ()) {
        drive.decryptFile(file: file, toFolder: toFolder, isOverwrite: isOverwrite, completion: completion)
    }
    
    func reshare(file: NXFileBase, newRecipients: [String], comment: String, completion: @escaping (Error?) -> ()) {
        drive.reshare(file: file, newRecipients: newRecipients, comment: comment, completion: completion)
    }
    func protectFile(type: NXProtectType ,path: String, right: NXRightObligation?, tags: [String: [String]]?, parentFile: SDMLNXLFile?, completion: @escaping (NXNXLFile?, Error?) -> ()) {
        drive.protectFile(type: type, path: path, right: right, tags: tags, parentFile: parentFile, completion: completion)
    }
    
    // MyVault.
    func getFileList(fromServer: Bool, completion: @escaping ([NXSyncFile]?, Error?) -> ()) {
        drive.getFileList(fromServer: fromServer, completion: completion)
    }
    
    func makeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.makeFileOffline(file: file, completion: completion)
    }
    
    func makeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.makeFileOnline(file: file, completion: completion)
    }
    
    func viewMyVaultFileOnline(file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String {
        return drive.viewMyVaultFileOnline(file: file, completion: completion)
    }
    func upload(file: NXFileBase, project: NXProjectModel?, progress: ((Double) -> ())?, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return drive.upload(file: file, project: project, progress: progress, completion: completion)
    }
    
    func cancel(id: String) -> Bool {
        return drive.cancel(id: id)
    }
    
    func remoteViewRepo(file:NXFileBase,repoId:String?,completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        drive.remoteViewRepo(file: file, repoId: repoId, completion: completion)
    }
    
    //ShareWithMe
    func getShareWithMeFileList(fromServer:Bool, completion:@escaping([NXSyncFile]?,Error?)->()) {
        drive.getShareWithMeFileList(fromServer: fromServer, completion: completion)
    }
    
    func sharedMakeFileOffline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.sharedMakeFileOffline(file: file, completion: completion)
    }
    
    func sharedMakeFileOnline(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.sharedMakeFileOnline(file: file, completion: completion)
    }
    
    func viewShareWithMeFileOnline( file:NXFileBase,completion:@escaping(NXFileBase?,Error?) -> ()) -> String {
        return drive.viewShareWithMeFileOnline(file: file, completion: completion)
    }
    
    //Project
    func getProjects(fromServer: Bool, completion: @escaping (NXProjectRoot?, Error?) -> ()) -> () {
        drive.getProjects(fromServer: fromServer, completion: completion)
    }
    
    func updateProject(project: NXProjectModel, completion: @escaping(NXProjectModel?,Error?) -> ()) -> () {
        drive.updateProject(project: project, completion: completion)
    }
    
    func getRightObligationWithTags(totalProject:SDMLProject?, isWorkspace: Bool, tags:[String:[String]],completion:@escaping(NXRightObligation?,Error?)->()) ->() {
        drive.getRightObligationWithTags(totalProject: totalProject, isWorkspace: isWorkspace, tags: tags, completion: completion)
    }
    
    func addNXLFileToProject(file: NXNXLFile?, goalProject: SDMLNXLFile, systemFilePath:String?, tags: [String:[String]], completion: @escaping(NXNXLFile?, Error?) -> ()) -> () {
        drive.addNXLFileToProject(file: file, goalProject: goalProject, systemFilePath: systemFilePath, tags: tags, completion: completion)
    }
    
    func viewFileOnlineOfProject(file: NXFileBase,completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return drive.viewFileOnlineOfProject(file: file, completion: completion)
    }
    
    func makeFileOfflineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.makeFileOfflineOfProject(file: file, completion: completion)
    }
    
    func makeFileOnlineOfProject(file: NXSyncFile, completion: @escaping (NXSyncFile?, Error?) -> ()) -> () {
        drive.makeFileOnlineOfProject(file: file, completion: completion)
    }
    
    func remoteViewProject(projectID:String,file:NXFileBase, completion: @escaping (SDMLRemoteViewResult?, Error?) -> ()) {
        drive.remoteViewProject(projectID: projectID, file: file, completion: completion)
    }
    
    func cancelDownload(id: String) -> Bool {
        return drive.cancelDownload(id: id)
    }
    
    // Workspace
    func getWorkspace() -> NXWorkspaceIF? {
        return drive.getWorkspace()
    }
    
    // Common
    static func getObligationForViewInfo(file:NXSyncFile, completion:@escaping(NXSyncFile?,Error?)->()) {
        NXClientService.getObligationForViewInfo(file: file, completion: completion)
    }
    
    func viewFileOnline(file: NXFileBase, completion: @escaping (NXFileBase?, Error?) -> ()) -> String {
        return drive.viewFileOnline(file: file, completion: completion)
    }
    
    
}
