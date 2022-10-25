//
//  NXSpecificProjectTitlePopupViewController.swift
//  skyDRM
//
//  Created by helpdesk on 3/1/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectTitlePopupViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NXHomeProjectView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var emptyImage: NSImageView!
    @IBOutlet weak var emptyLabel: NSTextField!
    var oldProjectInfo:NXProject?
    
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var nxProjects: NXProject?
    fileprivate var ownerProjectList: [NXProject] = [NXProject]()
    fileprivate var joinedProjectList: [NXProject] = [NXProject]()
    fileprivate var totalOwnerProjects: Int = 0
    fileprivate var totalJoinedProjects: Int = 0
    
    fileprivate var bProjectActivated = false
    fileprivate let listProjectsNumCeiling = 6
    fileprivate var shouldListJoinedProjects = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = WHITE_COLOR.cgColor
        
        emptyImage.isHidden = true
        emptyLabel.isHidden = true
        collectionView.collectionDelegate = self
        collectionView.scrollDelegate = self
        updateUIFromNetwork()
    }
    
    func updateProjectMenu() {
        let storage = NXProjectStorage()
        storage.pendingInvitationsList = NXLoginUser.sharedInstance.projects().pendingInvitationsList
        storage.ownerProjectList = ownerProjectList
        storage.joinedProjectList = joinedProjectList
        NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
    }
    
    fileprivate func updateUIFromNetwork(){
        let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling)", listProjectType: .ownedByUser, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
        shouldListJoinedProjects = true
        ownerProjectList.removeAll()
        joinedProjectList.removeAll()
        projectService?.listProject(filter: listFilter)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(self)
    }
    
    fileprivate func updateUI() {
        if bProjectActivated == false && joinedProjectList.count == 0 {
            collectionView.isHidden = true
            emptyImage.isHidden = false
            emptyLabel.isHidden = false
        }
        else {
            emptyImage.isHidden = true
            emptyLabel.isHidden = true
            collectionView.isHidden = false
            collectionView.pendingInvitationsList.removeAll()
            collectionView.joinedProjectList = joinedProjectList
            collectionView.ownerProjectList = ownerProjectList
            collectionView.totalOwnerProjects = totalOwnerProjects
            collectionView.totalJoinedProjects = totalJoinedProjects
            collectionView.hasNewProjectItem = bProjectActivated
            DispatchQueue.main.async {
                self.collectionView.reloadCollectionView()
            }
        }
    }
}

extension NXSpecificProjectTitlePopupViewController: NXProjectAdapterDelegate{
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int, projectList: [NXProject]?, error: Error?) {
        guard let projectList = projectList else{
            return
        }
        
        switch filter.listProjectType {
        case .ownedByUser:
            totalOwnerProjects = totalProjects
        case .userJoined:
            totalJoinedProjects = totalProjects
        default:
            break
        }
        for item in projectList {
            if item.projectId == oldProjectInfo?.projectId{
                continue
            }
            
            if item.ownedByMe {
                if ownerProjectList.count < listProjectsNumCeiling - 1 {
                    ownerProjectList.append(item)
                }
            }
            else {
                joinedProjectList.append(item)
            }
        }
        
        //check project has been activated or not
        bProjectActivated = true
        if ownerProjectList.count == 0 {
            if let oldProject = oldProjectInfo {
                if oldProject.ownedByMe == false {
                    bProjectActivated = false
                }
            }
            else {
                bProjectActivated = false
            }
        }
        //update menu
        if shouldListJoinedProjects {
            let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling)", listProjectType: .userJoined, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
            shouldListJoinedProjects = false
            projectService?.listProject(filter: listFilter)
        }
        else {
            let storage = NXProjectStorage()
            storage.pendingInvitationsList = NXLoginUser.sharedInstance.projects().pendingInvitationsList
            storage.ownerProjectList = ownerProjectList
            storage.joinedProjectList = joinedProjectList
            NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
            updateUI()
        }
        
    }
    
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        guard error == nil else{
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_FAIL", comment: ""))
            return
        }
        NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_SUCCESS", comment: ""))
        let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling)", listProjectType: .ownedByUser, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
        shouldListJoinedProjects = false
        ownerProjectList.removeAll()
        projectService?.listProject(filter: listFilter)
    }
    
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        if error == nil {
            inviteMemberAlreadyInProjectTips(alreadyInvited: alreadyInvited!, nowInvited: nowInvited!, alreadyMembers: alreadyMembers!)
        }else{
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
    }
    
    private func findProject(id: String) -> NXProject? {
        for project in ownerProjectList {
            if project.projectId == id {
                return project
            }
        }
        for project in joinedProjectList {
            if project.projectId == id {
                return project
            }
        }
        return nil
    }

    private func inviteMemberAlreadyInProjectTips(alreadyInvited: [String], nowInvited: [String], alreadyMembers: [String]) {
        let already = alreadyInvited + alreadyMembers
        let alreadyStr = already.joined(separator: ",")
        
        if nowInvited.count == 0 {
            NSAlert.showAlert(withMessage: String(format: NSLocalizedString("PROJECT_MEMBER_EMAIL_FALIED", comment: ""), alreadyStr))
        } else {
            if alreadyStr == "" {
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_SUCCESS", comment: ""))
            } else {
                NSAlert.showAlert(withMessage: String(format: NSLocalizedString("PROJECT_MEMBER_EMAIL_PART_FAILED", comment: ""), alreadyStr))
            }
        }
    }
}

extension NXSpecificProjectTitlePopupViewController: NXScrollWheelCollectionViewDelegate {
    func onScrollWheel(event: NSEvent) {
        scrollView.scrollWheel(with: event)
    }
}

//MARK: NXHomeProjectViewDelegate
extension NXSpecificProjectTitlePopupViewController: NXHomeProjectViewDelegate {
    func onAccept(invitation: NXProjectInvitation) {
    }
    func onDecline(invitation: NXProjectInvitation) {
    }
    func onInvite(projectId: String, emailArray: [String], invitationMsg: String) {
        let project = NXProject()
        project.projectId = projectId
        project.invitationMsg = invitationMsg
        
        var members = [NXProjectMember]()
        for item in emailArray{
            let member = NXProjectMember()
            member.email = item
            members.append(member)
        }
        projectService?.projectInvitation(project: project, members: members)
    }
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String) {
        let project = NXProject()
        project.name = title
        project.projectDescription = description
        project.invitationMsg = invitationMsg
        projectService?.createProject(project: project, invitedEmails: emailArray)
    }
    func onShowAllProjects() {
        self.presentingViewController?.dismiss(self)
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
            let vc = appDelegate.mainWindow?.contentViewController as? ViewController {
            vc.homeOpenProject()
        }
    }
    func beforeSelectItem(projectInfo: NXProject) {
        self.presentingViewController?.dismiss(self)
    }
}

extension NXSpecificProjectTitlePopupViewController: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onProjectPopupSheet()
    }
}
