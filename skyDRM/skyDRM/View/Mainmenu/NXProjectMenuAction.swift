//
//  NXProjectMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectMenuAction: NSObject {
    static let shared = NXProjectMenuAction()
    
    private var ownerProjectListContext = 0
    private var joinedProjectListContext = 0
    private var specificProjectInfoContext = 0
    override private init() {
        super.init()
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "ownerProjectList", options: .new, context: &ownerProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "joinedProjectList", options: .new, context: &joinedProjectListContext)
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &specificProjectInfoContext)
    }
    deinit {
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "ownerProjectList", context: &ownerProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "joinedProjectList", context: &joinedProjectListContext)
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &ownerProjectListContext ||
            context == &joinedProjectListContext {
            updateMainMenuItem()
            refreshProject()
        }
        else if context == &specificProjectInfoContext {
            refreshOneProject(project: NXSpecificProjectData.shared.getProjectInfo())
        }
        else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
   @objc  func goto() {
    }
  @objc   func create() {
        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            if vc.currentSubViewInContent is NXHomeView {
                guard let homeProjectView = vc.homeView?.homeBottomView?.collectionView else {
                    return
                }
                homeProjectView.onCreateProjectCreate()
            }
            else if vc.currentSubViewInContent is NXFileListView {
                guard let popupVC = NSApplication.shared.mainWindow?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController  else {
                    return
                }
                guard let homeProjectView = popupVC.collectionView else {
                    return
                }
                homeProjectView.onCreateProjectCreate()
            }
            else if vc.currentSubViewInContent is NXMainProjectView {
                guard let homeProjectView = vc.mainProjectView?.collectionView else {
                    return
                }
                homeProjectView.onCreateProjectCreate()
            }
        }
        else if let _ = NSApplication.shared.mainWindow?.contentViewController as? NXSpecificProjectViewController {
            guard let popupVC = NSApplication.shared.mainWindow?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController  else {
                return
            }
            guard let homeProjectView = popupVC.collectionView else {
                return
            }
            homeProjectView.onCreateProjectCreate()
        }
        
    }
  @objc   func invite() {
        let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
        if vc?.contentSubView is NXSpecificProjectHomeView {
            guard let peopleView = vc?.homeView.people else {
                return
            }
            peopleView.invitePeople()
        }
        else if vc?.contentSubView is NXProjectMemberView {
            guard let peopleView = vc?.peoplesView else {
                return
            }
            peopleView.onTapInviteButton(peopleView.invitebutton!)
        }
    }
    @objc func addfile() {
        let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
        if vc?.contentSubView is NXSpecificProjectHomeView {
            guard let recentView = vc?.homeView.recentFiles else {
                return
            }
            recentView.addFile()
        }
        else if vc?.contentSubView is NXSpecificProjectFilesView {
            vc?.filesView.fileOperationBarDelegate(type: .uploadFile, userData: nil)
        }
    }
  @objc   func manage() {
        print("manage")
    }
    private func updateMainMenuItem() {
        if NXLoginUser.sharedInstance.projects().ownerProjectList.count == 0 {
            if NXLoginUser.sharedInstance.projects().joinedProjectList.count == 0 {
                let project: NXMainMenu = .project
                project.menuItem?.isHidden = true
            }
            else {
                let project: NXMainMenu = .project
                project.menuItem?.isHidden = false
                let create: NXProjectMenu = .create
                create.menuItem?.isEnabled = false
            }
        }
        else {
            let project: NXMainMenu = .project
            project.menuItem?.isHidden = false
            let create: NXProjectMenu = .create
            create.menuItem?.isEnabled = true
        }
    }
    private func refreshProject() {
        let gotoMenu: NXProjectMenu = .goto
        let subMenu = gotoMenu.submenu
        subMenu?.removeAllItems()
        
        let projects = NXLoginUser.sharedInstance.projects()
        var displayProjects = [NXProject]()
        _ = projects.joinedProjectList.map({displayProjects.append($0)})
        _ = projects.ownerProjectList.map({displayProjects.append($0)})
        
        for project in displayProjects {
            if let name = project.displayName,
                let projectId = project.projectId {
                let newItem = createProjectItem(title: name, id: projectId)
                subMenu?.addItem(newItem)
            }
        }
        checkDisplayedProject(menu: subMenu!)
    }
    private func refreshOneProject(project: NXProject) {
        let gotoMenu: NXProjectMenu = .goto
        guard let subMenu = gotoMenu.submenu,
            let displayName = project.displayName,
            let projectId = project.projectId else {
            return
        }
        for item in subMenu.items {
            if item.representedObject as? String == projectId {
                item.title = displayName
                return
            }
        }
    }
    private func checkDisplayedProject(menu: NSMenu) {
        guard let projectWindow = NXSpecificProjectWindow.sharedInstance.window else {
            return
        }
        if projectWindow.isVisible {
            if let displayName = NXSpecificProjectData.shared.getProjectInfo().displayName,
                let projectId = NXSpecificProjectData.shared.getProjectInfo().projectId {
                for item in menu.items {
                    if item.title == displayName,
                        item.representedObject as? String == projectId {
                        item.state = NSControl.StateValue.on
                    }
                    else {
                        item.state = NSControl.StateValue.off
                    }
                }
            }
        }
    }
    private func createProjectItem(title: String, id: String) -> NSMenuItem {
        let menu = NSMenuItem(title: title, action: #selector(NXProjectMenuAction.gotoProject), keyEquivalent: "")
        menu.target = self
        menu.representedObject = id
        return menu
    }
    @objc public func gotoProject(sender: NSMenuItem) {
        let findProject = {() -> NXProject? in
            let projects = NXLoginUser.sharedInstance.projects()
            var displayProjects = [NXProject]()
            _ = projects.joinedProjectList.map({displayProjects.append($0)})
            _ = projects.ownerProjectList.map({displayProjects.append($0)})
            for project in displayProjects {
                if project.displayName == sender.title &&
                    project.projectId == sender.representedObject as? String {
                    return project
                }
            }
            return nil
        }
        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            if vc.currentSubViewInContent is NXHomeView {
                guard let homeProjectView = vc.homeView?.homeBottomView?.collectionView else {
                    return
                }
                guard let info = findProject() else {
                    return
                }
                homeProjectView.selectProjectItem(info: info)
            }
            else if vc.currentSubViewInContent is NXFileListView {
                if let popupVC = NSApplication.shared.mainWindow?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController {
                    guard let homeProjectView = popupVC.collectionView else {
                        return
                    }
                    guard let info = findProject() else {
                        return
                    }
                    homeProjectView.selectProjectItem(info: info)
                }
                else {
                    let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
                    guard let info = findProject() else {
                        return
                    }
                    vc?.initData(projectInfo: info)
                    NXSpecificProjectWindow.sharedInstance.showWindow()
                }
            }
            else if vc.currentSubViewInContent is NXMainProjectView {
                let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
                guard let info = findProject() else {
                    return
                }
                vc?.initData(projectInfo: info)
                NXSpecificProjectWindow.sharedInstance.showWindow()
            }
        }
        else if let _ = NSApplication.shared.mainWindow?.contentViewController as? NXSpecificProjectViewController {
            if let popupVC = NSApplication.shared.mainWindow?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController {
                guard let homeProjectView = popupVC.collectionView else {
                    return
                }
                guard let info = findProject() else {
                    return
                }
                homeProjectView.selectProjectItem(info: info)
            }
            else {
                let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
                guard let info = findProject() else {
                    return
                }
                vc?.initData(projectInfo: info)
                NXSpecificProjectWindow.sharedInstance.showWindow()
            }
        }    
    }
}
