//
//  SpecificProjectViewController.swift
//  skyDRM
//
//  Created by helpdesk on 2/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectViewController: NSViewController {
    
    @IBOutlet weak var titleSection: NSView!
    @IBOutlet weak var leftNav: NSView!
    @IBOutlet weak var contentView: NSView!
    
    lazy var titlePopupViewController:NXSpecificProjectTitlePopupViewController = {
        let titleViewController = NXSpecificProjectTitlePopupViewController()
        return titleViewController
    }()
    
    var contentSubView:NSView?
    fileprivate var currentSelectionNum:Int!

    fileprivate var titleView: NXSpecificProjectTitleView!
    fileprivate var navView: NXSpecificProjectNavigationView!
    var homeView: NXSpecificProjectHomeView!
    var filesView: NXSpecificProjectFilesView!
    var peoplesView: NXProjectMemberView!
    var configurationView: NXProjectConfigurationView!
    
    private var service: NXProjectAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        titleView = NXCommonUtils.createViewFromXib(xibName: "NXSpecificProjectTitleView", identifier: "NXSpecificProjectTitleView", frame: nil, superView: titleSection) as? NXSpecificProjectTitleView
        titleView.delegate = self
        
        navView = NXCommonUtils.createViewFromXib(xibName: "NXSpecificProjectNavigationView", identifier: "NXSpecificProjectNavigation", frame: nil, superView: leftNav) as? NXSpecificProjectNavigationView
        navView.delegate = self
    }
    
    override func viewWillAppear() {
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = GREEN_COLOR.cgColor
        self.view.window?.delegate = self
        
        // Get invitationMsg
        let projectInfo = NXSpecificProjectData.shared.getProjectInfo()
        if projectInfo.invitationMsg == nil {
            if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
                service = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
                service?.delegate = self
                service?.getProjectMetadata(project: NXSpecificProjectData.shared.getProjectInfo())
            }
        }
        
    }
    
    open func initData(projectInfo: NXProject){
        NXSpecificProjectData.shared.setProjectInfo(info: projectInfo)
    }
}

extension NXSpecificProjectViewController:NXSpecificProjectNavDelegate{
    func onNavigate(index: Int) {
        contentView?.subviews.removeAll()
        switch index{
        case 0:
            currentSelectionNum = 0
            homeView = NXCommonUtils.createViewFromXib(xibName: "NXSpecificProjectHomeView", identifier: "NXSpecificProjectHomeView", frame: nil, superView: contentView) as? NXSpecificProjectHomeView
            homeView.delegate = self
            contentSubView = homeView
        case 1:
            currentSelectionNum = 1
            filesView = NXCommonUtils.createViewFromXib(xibName: "NXSpecificProjectFilesView", identifier: "NXSpecificProjectFilesView", frame: nil, superView: contentView) as? NXSpecificProjectFilesView
            contentSubView = filesView
        case 2:
            currentSelectionNum = 2
            peoplesView = NXCommonUtils.createViewFromXib(xibName: "NXProjectMemberView", identifier: "NXProjectMemberView", frame: nil, superView: contentView) as? NXProjectMemberView
            contentSubView = peoplesView
        case 3:
            currentSelectionNum = 3
            configurationView = NXCommonUtils.createViewFromXib(xibName: "NXProjectConfigurationView", identifier: "NXProjectConfigurationView", frame: nil, superView: contentView) as? NXProjectConfigurationView
            contentSubView = configurationView
        default:
            break
        }
        updateMainMenu()
    }
}

extension NXSpecificProjectViewController:NXSpecificProjectTitleDelegate{
    func onBackClick() {
        self.view.window?.close()
    }
    
    func onTitleClick(projectInfo: NXProject) {
        titlePopupViewController.oldProjectInfo = projectInfo
        self.presentAsSheet(titlePopupViewController)
    }
    
    func onAddClick() {
    }
}

extension NXSpecificProjectViewController:NXSpecificProjectHomeDelegate{
    func viewAllFiles() {
        currentSelectionNum = 1
        navView?.tableView.selectRowIndexes([1], byExtendingSelection: false)
    }
    
    func viewAllPeople() {
        currentSelectionNum = 2
        navView?.tableView.selectRowIndexes([2], byExtendingSelection: false)
    }
}

extension NXSpecificProjectViewController: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        updateMainMenu()
    }
    func windowDidBecomeMain(_ notification: Notification) {
        updateMainMenu()
    }
    func windowDidResignMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidResignKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowWillClose(_ notification: Notification) {
        NXMainMenuHelper.shared.unCheckAllProject()
    }
    fileprivate func updateMainMenu() {
        if let _ = self.view.window?.attachedSheet {
            NXMainMenuHelper.shared.onModalSheetWindow()
        }
        else {
            NXMainMenuHelper.shared.onSpecificProjectVC()
            if contentSubView is NXSpecificProjectHomeView {
                NXMainMenuHelper.shared.onSpecificProjectViewHome()
            }
            else if contentSubView is NXSpecificProjectFilesView {
                NXMainMenuHelper.shared.onSpecificProjectViewTable()
                if let filesView = filesView {
                    if filesView.selectedFiles.count > 0 {
                        NXMainMenuHelper.shared.onSpecificProjectTableSelectFile(file: filesView.selectedFiles[0], ownedByMe: NXSpecificProjectData.shared.getProjectInfo().ownedByMe)
                    }
                    else {
                        NXMainMenuHelper.shared.onSpecificProjectTableDeselectFile()
                    }
                }
            }
            else if contentSubView is NXProjectMemberView {
                NXMainMenuHelper.shared.onSpecificProjectViewMember()
            }
            else if contentSubView is NXProjectConfigurationView {
                NXMainMenuHelper.shared.onSpecificProjectConfiguration()
            }
            
            if let displayName = NXSpecificProjectData.shared.getProjectInfo().displayName,
                let projectId = NXSpecificProjectData.shared.getProjectInfo().projectId {
                NXMainMenuHelper.shared.checkProject(displayName: displayName, id: projectId)
            }
        }
        updateProjectMenu()
    }
    fileprivate func updateProjectMenu() {
        if let popupProjectVC = view.window?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController {
            popupProjectVC.updateProjectMenu()
        }
    }
}

extension NXSpecificProjectViewController: NXProjectAdapterDelegate {
    // update invitationMsg
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?) {
        guard let project = project else {
            return
        }
        
        let projectInfo = NXSpecificProjectData.shared.getProjectInfo()
        projectInfo.invitationMsg = project.invitationMsg
        NXSpecificProjectData.shared.setProjectInfo(info: projectInfo)
    }
}
