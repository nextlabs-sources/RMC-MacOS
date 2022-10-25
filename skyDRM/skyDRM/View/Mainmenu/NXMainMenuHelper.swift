//
//  MainMenuHelper.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

class NXMainMenuHelper: NSObject {
    
    static let shared = NXMainMenuHelper()

    private override init() {
        super.init()
        
        let skyAction = NXSkyDrmMenuAction.shared
        let about: NXSkyDrmMenu = .about
        about.menuItem?.target = skyAction
        about.menuItem?.action = #selector(NXSkyDrmMenuAction.about)
        let fileAction = NXFileMenuAction.shared
        let openFile: NXFileMenu = .open
        openFile.menuItem?.target = fileAction
        openFile.menuItem?.action = #selector(NXFileMenuAction.openFile)
        let protectFile: NXFileMenu = .protect
        protectFile.menuItem?.target = fileAction
        protectFile.menuItem?.action = #selector(NXFileMenuAction.protectFile)
        let shareFile: NXFileMenu = .share
        shareFile.menuItem?.target = fileAction
        shareFile.menuItem?.action = #selector(NXFileMenuAction.shareFile)
        let uploadFile: NXFileMenu = .upload
         uploadFile.menuItem?.target = fileAction
        uploadFile.menuItem?.action = #selector(NXFileMenuAction.uploadFile)
        let stopUploadFile: NXFileMenu = .stopUpload
        stopUploadFile.menuItem?.target = fileAction
        stopUploadFile.menuItem?.action = #selector(NXFileMenuAction.stopUpload)
        let deleteFile: NXFileMenu = .delete
        deleteFile.menuItem?.target = fileAction
        deleteFile.menuItem?.action = #selector(NXFileMenuAction.deleteFile)
        let info: NXFileMenu = .info
        info.menuItem?.target = fileAction
        info.menuItem?.action = #selector(NXFileMenuAction.getInfo)
        let log: NXFileMenu = .log
        log.menuItem?.target = fileAction
//        log.menuItem?.action = #selector(NXFileMenuAction.getActivityLog)
          let signout: NXFileMenu = .signout
        signout.menuItem?.target = fileAction
        signout.menuItem?.action = #selector(NXFileMenuAction.signout)
        
        let viewAction = NXViewMenuAction.shared
//        let previous: NXViewMenu = .previous
//        previous.menuItem?.target = viewAction
//        previous.menuItem?.action = #selector(NXViewMenuAction.previous)
//
//        let next: NXViewMenu = .next
//        next.menuItem?.target = viewAction
//        next.menuItem?.action = #selector(NXViewMenuAction.next)
//        let refresh: NXViewMenu = .refresh
//        refresh.menuItem?.target = viewAction
//        refresh.menuItem?.action = #selector(NXViewMenuAction.refresh)
//        let mydrive: NXViewMenu = .mydrive
//        mydrive.menuItem?.target = viewAction
//        mydrive.menuItem?.action = #selector(NXViewMenuAction.gotoMydrive)
//        let myvault: NXViewMenu = .myvault
//        myvault.menuItem?.target = viewAction
//        myvault.menuItem?.action = #selector(NXViewMenuAction.gotoMyvault)
//        let gotohome: NXViewMenu = .gotohome
//        gotohome.menuItem?.target = viewAction
//        gotohome.menuItem?.action = #selector(NXViewMenuAction.gotoHome)
        let sortby: NXViewMenu = .sortby
        sortby.menuItem?.target = viewAction
        sortby.menuItem?.action = #selector(NXViewMenuAction.sortby)
        let sortbyFilename: NXSortbyMenu = .fileName
        sortbyFilename.menuItem?.target = viewAction
        sortbyFilename.menuItem?.action = #selector(NXViewMenuAction.sortbyFileName)
        let sortbyLastModified: NXSortbyMenu = .lastmodified
        sortbyLastModified.menuItem?.target = viewAction
        sortbyLastModified.menuItem?.action = #selector(NXViewMenuAction.sortbyLastModified)
        let sortbyFilesize: NXSortbyMenu = .fileSize
        sortbyFilesize.menuItem?.target = viewAction
        sortbyFilesize.menuItem?.action = #selector(NXViewMenuAction.sortbyFileSize)
        
//        let manageAction = NXManageMenuAction.shared
//        let search: NXManageMenu = .search
//        search.menuItem?.target = manageAction
//        search.menuItem?.action = #selector(NXManageMenuAction.search)
//        let addRepository: NXManageMenu = .addRepository
//        addRepository.menuItem?.target = manageAction
//        addRepository.menuItem?.action = #selector(NXManageMenuAction.addRepository)
//        let repositories: NXManageMenu = .repositories
//        repositories.menuItem?.target = manageAction
//        repositories.menuItem?.action = #selector(NXManageMenuAction.repositories)
//        let localFile: NXManageMenu = .localFile
//        localFile.menuItem?.target = manageAction
//        localFile.menuItem?.action = #selector(NXManageMenuAction.openLocalfile)
//        let profile: NXManageMenu = .profile
//        profile.menuItem?.target = manageAction
//        profile.menuItem?.action = #selector(NXManageMenuAction.profile)
//        let account: NXManageMenu = .account
//        account.menuItem?.target = manageAction
//        account.menuItem?.action = #selector(NXManageMenuAction.account)
//        let usage: NXManageMenu = .usage
//        usage.menuItem?.target = manageAction
//        usage.menuItem?.action = #selector(NXManageMenuAction.usage)
//        let preferences: NXManageMenu = .preferences
//        preferences.menuItem?.target = manageAction
//        preferences.menuItem?.action = #selector(NXManageMenuAction.preferences)
//        
//        let projectAction = NXProjectMenuAction.shared
//        let goto: NXProjectMenu = .goto
//        goto.menuItem?.target = projectAction
//        goto.menuItem?.action = #selector(NXProjectMenuAction.goto)
//        let create: NXProjectMenu = .create
//        create.menuItem?.target = projectAction
//        create.menuItem?.action = #selector(NXProjectMenuAction.create)
//        let invite: NXProjectMenu = .invite
//        invite.menuItem?.target = projectAction
//        invite.menuItem?.action = #selector(NXProjectMenuAction.invite)
//        let addfile: NXProjectMenu = .addfile
//        addfile.menuItem?.target = projectAction
//        addfile.menuItem?.action = #selector(NXProjectMenuAction.addfile)
//        let manage: NXProjectMenu = .manage
//        manage.menuItem?.target = projectAction
//        manage.menuItem?.action = #selector(NXProjectMenuAction.manage)
        
        let helpAction = NXHelpMenuAction.shared
        let gettingStarted: NXHelpMenu = .gettingStarted
        gettingStarted.menuItem?.target = helpAction
        gettingStarted.menuItem?.action = #selector(NXHelpMenuAction.gettingStarted)
        let help: NXHelpMenu = .help
        help.menuItem?.target = helpAction
        help.menuItem?.action = #selector(NXHelpMenuAction.help)
//        let update: NXHelpMenu = .update
//        update.menuItem?.target = helpAction
//        update.menuItem?.action = #selector(NXHelpMenuAction.checkforUpdate)
//        let report: NXHelpMenu = .report
//        report.menuItem?.target = helpAction
//        report.menuItem?.action = #selector(NXHelpMenuAction.report)
        
        self.addObserver()
        
    }
    
    deinit {
        self.removeObserver()
    }
    
    func enableUpload(enable: Bool) {

    }
    func enablePrevious(enable: Bool) {

    }
    
    func enableNext(enable: Bool) {

    }

    func unCheckAllProject() {

    }
    func checkProject(displayName: String, id: String) {

    }
    
    func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .login, object: nil)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc  func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .login {
            loginMenu()
        } else if notification.nxNotification == .logout {
            logoutMenu()
        }
    }
}


extension NXMainMenuHelper {
    func logoutMenu() {
        let file: NXMainMenu = .file
        file.menuItem?.isHidden = true
        let view: NXMainMenu = .view
        view.menuItem?.isHidden = true
    }
    
    func loginMenu() {
        let file: NXMainMenu = .file
        file.menuItem?.isHidden = false
        let view: NXMainMenu = .view
        view.menuItem?.isHidden = false
    }
}

// MARK: - ViewController
extension NXMainMenuHelper {
    func onMainViewController() {
    }
    func onHomeView() {
    }
    func onFileListView() {

    }
    func onSelectFile(file: NXFileBase) {
        
    }
    
    func onSelectFileEx(file: NXFileBase, is3rdRepo: Bool) {
        
    }
    
    
    func onDeselectFile() {

    }
    func onProjectHomeView() {

    }
    
    func settingShareWithMeMenu(with rights: [NXRightType]?) {

    }
}

// MARK: - Specific Project View controller
extension NXMainMenuHelper {
    func onSpecificProjectTableSelectFile(file: NXFileBase, ownedByMe: Bool) {
    }
    func onSpecificProjectTableDeselectFile() {

    }
    func onSpecificProjectVC() {
        //skyDRM
    }
    func onSpecificProjectViewHome() {
        //File
    }
    func onSpecificProjectViewTable() {
        //File
    }
    func onSpecificProjectViewMember() {
        //File
    }
    func onSpecificProjectConfiguration() {
        //File
    }
}

// MARK: - File Render Window
extension NXMainMenuHelper {
    func onFileRenderWindow() {
        //skyDRM
    }
}
// MARK: - modal/sheet window
extension NXMainMenuHelper {
    func onModalSheetWindow() {
        //skyDRM
    }
    func onProjectPopupSheet() {
        //skyDRM
    }
    
}

extension NXMainMenuHelper {
    func onProjectActivate() {
        //skyDRM
    }
}
