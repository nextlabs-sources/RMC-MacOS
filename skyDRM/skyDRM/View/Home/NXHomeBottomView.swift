//
//  NXHomeBottomView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/2.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeBottomViewDelegate: NSObjectProtocol {
    func showAllProjects()
    func activateProject()
}

class NXHomeBottomView: NXFrameChangeView {

    @IBOutlet weak var collectionView: NXHomeProjectView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var customView: NSView!
    fileprivate var projectService: NXProjectAdapter?
    
    fileprivate let leftRightGap: CGFloat = 30
    fileprivate let bottomGap: CGFloat = 10
    fileprivate let activateHeightConst: CGFloat = 80
    
    fileprivate var declineInvitation = NXProjectInvitation()
    fileprivate let waitingView = NXProgressIndicatorView()
    
    private var pendingInvitationsContext = 0
    private var ownerProjectListContext = 0
    private var joinedProjectListContext = 0
    private var specificProjectInfoContext = 0
    
    fileprivate let listProjectsNumCeiling = 6
    fileprivate var shouldListJoinedProjects = true
    fileprivate var isRetrievingNetworkData = false
    
    fileprivate var tempPendingInvitations = [NXProjectInvitation]()
    fileprivate var tempOwnerProjects = [NXProject]()
    fileprivate var tempJoinedProjects = [NXProject]()
    fileprivate var totalOwnerProjects: Int = 0
    fileprivate var totalJoinedProjects: Int = 0
    
    private var activateView: NXProjectActivateView?
    private var bFirstUpdate = true
    weak var delegate: NXHomeBottomViewDelegate?
    fileprivate var isRefreshTriggeredBySelf = false
    fileprivate var showActivateView = false
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        waitingView.removeFromSuperview()
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "pendingInvitationsList")
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "ownerProjectList")
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "joinedProjectList")
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview,
            let profile = NXLoginUser.sharedInstance.nxlClient?.profile else{
            return
        }
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "pendingInvitationsList", options: .new, context: &pendingInvitationsContext)
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "ownerProjectList", options: .new, context: &ownerProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "joinedProjectList", options: .new, context: &joinedProjectListContext)
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &specificProjectInfoContext)
        projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
        projectService?.delegate = self
        collectionView.collectionDelegate = self
        collectionView.scrollDelegate = self
        scrollView.frame = NSMakeRect(bounds.minX+leftRightGap, bounds.minY+bottomGap, bounds.width-leftRightGap*2, bounds.height)
        scrollView.isHidden = true
        
        addSubview(waitingView)
        
        customView?.frame = NSMakeRect(bounds.minX+leftRightGap, bounds.minY+bottomGap, bounds.width-leftRightGap*2, bounds.height)
        activateView = NXCommonUtils.createViewFromXib(xibName: "NXProjectActivateView", identifier: "projectActivateView", frame: nil, superView: customView) as? NXProjectActivateView
        activateView?.delegate = self
        activateView?.isHidden = true
        
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &pendingInvitationsContext ||
            context == &ownerProjectListContext ||
            context == &joinedProjectListContext {
            syncProjects()
        }
        else if context == &specificProjectInfoContext {
            syncOneProject(project: NXSpecificProjectData.shared.getProjectInfo())
            refreshOneItem(project: NXSpecificProjectData.shared.getProjectInfo())
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    func updateProjectMenu() {
        let storage = NXProjectStorage()
        storage.pendingInvitationsList = tempPendingInvitations
        storage.ownerProjectList = tempOwnerProjects
        storage.joinedProjectList = tempJoinedProjects
        isRefreshTriggeredBySelf = true
        NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
    }
    
    private func syncProjects() {
        if isRefreshTriggeredBySelf {
            isRefreshTriggeredBySelf = false
        }
        else {
            //sync projects
            for ownerGlobal in NXLoginUser.sharedInstance.projects().ownerProjectList {
                for (localId, ownerLocal) in tempOwnerProjects.enumerated() {
                    if ownerGlobal == ownerLocal {
                        tempOwnerProjects[localId] = ownerGlobal.copy() as! NXProject
                    }
                }
            }
            for joinedGlobal in NXLoginUser.sharedInstance.projects().joinedProjectList {
                for (localId, joinedLocal) in tempJoinedProjects.enumerated() {
                    if joinedGlobal == joinedLocal {
                        tempJoinedProjects[localId] = joinedGlobal.copy() as! NXProject
                    }
                }
            }
        }
    }
    private func syncOneProject(project: NXProject) {
        for (localId, ownerLocal) in tempOwnerProjects.enumerated() {
            if project == ownerLocal {
                tempOwnerProjects[localId] = project.copy() as! NXProject
                return
            }
        }
        for (localId, joinedLocal) in tempJoinedProjects.enumerated() {
            if project == joinedLocal {
                tempJoinedProjects[localId] = project.copy() as! NXProject
                return
            }
            
        }
    }
    fileprivate func updateUI() {
        activateView?.isHidden = true
        scrollView.isHidden = true
        collectionView.pendingInvitationsList = tempPendingInvitations
        collectionView.joinedProjectList = tempJoinedProjects
        collectionView.ownerProjectList = tempOwnerProjects
        collectionView.totalOwnerProjects = totalOwnerProjects
        collectionView.totalJoinedProjects = totalJoinedProjects
        DispatchQueue.main.async {
            self.collectionView.reloadCollectionView()
            self.insertCollectionAndActivate(pendingCount: self.collectionView.pendingInvitationsList.count, createByMeCount: self.collectionView.ownerProjectList.count, createByOtherCount: self.collectionView.joinedProjectList.count)
        }
    }
    fileprivate func refreshOneItem(project: NXProject) {
        DispatchQueue.main.async {
            self.collectionView.reloadCollectionItem(project: project)
        }
    }
    func updateAccountName() {
        let updateProject: (_: String, _: String, _: NXProject) -> Void = { name, userId, project in
            guard let members = project.projectMembers else {
                return
            }
            for member in members {
                if member.userId == userId {
                    member.displayName = name
                    break
                }
            }
        }
        guard let profile = NXLoginUser.sharedInstance.nxlClient?.profile,
            let name = profile.userName,
            let userId = profile.userId else {
                return
        }
        for project in tempOwnerProjects {
            updateProject(name, userId, project)
        }
        for project in tempJoinedProjects {
            updateProject(name, userId, project)
        }
        //sync common data
        let storage = NXProjectStorage()
        storage.pendingInvitationsList = tempPendingInvitations
        storage.ownerProjectList = tempOwnerProjects
        storage.joinedProjectList = tempJoinedProjects
        isRefreshTriggeredBySelf = true
        NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
        //refresh UI
        collectionView.pendingInvitationsList = tempPendingInvitations
        collectionView.joinedProjectList = tempJoinedProjects
        collectionView.ownerProjectList = tempOwnerProjects
        collectionView.totalOwnerProjects = totalOwnerProjects
        collectionView.totalJoinedProjects = totalJoinedProjects
        collectionView.reloadCollectionView()
    }
    func updateUIFromNetwork() {
        if isRetrievingNetworkData {
            return
        }
        isRetrievingNetworkData = true
        if bFirstUpdate {
            bFirstUpdate = false
            waitingView.frame = NSZeroRect
        }
        else {
            waitingView.frame = bounds
        }
        waitingView.startAnimation()
        projectService?.listPendingInvitationForUser()
    }
//    MARK: private
    fileprivate func insertCollectionAndActivate(pendingCount: Int, createByMeCount: Int, createByOtherCount: Int) {
        var activateHeight: CGFloat = 0
        var collectionHeight: CGFloat = 0
        //collection
        var headercount = 0
        if pendingCount != 0 {
            headercount += 1
        }
        if createByMeCount != 0 {
            headercount += 1
        }
        if createByOtherCount != 0 {
            headercount += 1
        }
        if headercount != 0 {
            let headerH = NXHomeProjectView.UIConstant.headerHeight
            let sectionSpacingH = NXHomeProjectView.UIConstant.rowSpacing
            let allHeaderHeight = CGFloat(headercount)*headerH+CGFloat(headercount-1)*sectionSpacingH
            collectionHeight = allHeaderHeight
            let calcSectionHeight = {(count: Int, itemHeight: CGFloat, rowSpacing: CGFloat) -> CGFloat in
                let row: Int = (count+2)/3
                if row > 0 {
                    let rowHeight: CGFloat = CGFloat(row)*itemHeight
                    let gapHeight: CGFloat = CGFloat(row-1)*rowSpacing
                    return rowHeight+gapHeight
                }
                return 0
            }
            let itemHeight = NXHomeProjectView.UIConstant.itemHeight
            let rowSpacing = NXHomeProjectView.UIConstant.rowSpacing
            collectionHeight += calcSectionHeight(pendingCount, itemHeight, rowSpacing)
            collectionHeight += calcSectionHeight(createByMeCount, itemHeight, rowSpacing)
            collectionHeight += calcSectionHeight(createByOtherCount, itemHeight, rowSpacing)
            collectionHeight += bottomGap
            scrollView.isHidden = false
        }
        //activate
        if createByMeCount == 0 && showActivateView {
            activateHeight = activateHeightConst
            activateView?.isHidden = false
        }
        self.frame.size.height = collectionHeight + activateHeight
        scrollView.frame = NSMakeRect(bounds.minX+leftRightGap, bottomGap, frame.size.width-2*leftRightGap, collectionHeight)
        customView?.frame = NSMakeRect(bounds.minX+leftRightGap, bottomGap+collectionHeight, frame.size.width-2*leftRightGap, activateHeight)
        frameDelegate?.onFrameChange(frame: frame)
    }
}

//MARK: NXProjectAdapterDelegate
extension NXHomeBottomView: NXProjectAdapterDelegate {
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int,  projectList: [NXProject]?, error: Error?) {
        showActivateView = error == nil ? true : false
        guard let projectList = projectList else {
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
            if item.ownedByMe {
                tempOwnerProjects.append(item)
            }
            else {
                tempJoinedProjects.append(item)
            }
        }
        if shouldListJoinedProjects {
            let listFilter = NXListProjectFilter(page: "\(1)", size: "\(listProjectsNumCeiling)", listProjectType: .userJoined, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
            shouldListJoinedProjects = false
            projectService?.listProject(filter: listFilter)
        }
        else {
            let storage = NXProjectStorage()
            storage.pendingInvitationsList = tempPendingInvitations
            storage.ownerProjectList = tempOwnerProjects
            storage.joinedProjectList = tempJoinedProjects
            isRefreshTriggeredBySelf = true
            NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
            updateUI()
            waitingView.stopAnimation()
            isRetrievingNetworkData = false
        }
        
    }
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?) {
        tempPendingInvitations.removeAll()
        if var pendingList = pendingList{
            pendingList.sort(by: {
                return $0.inviteTime > $1.inviteTime
            })
            tempPendingInvitations = pendingList
            
        }
        let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling-1)", listProjectType: .ownedByUser, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
        shouldListJoinedProjects = true
        tempOwnerProjects.removeAll()
        tempJoinedProjects.removeAll()
        projectService?.listProject(filter: listFilter)
    }
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        if error != nil {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_FAIL", comment: ""))
            waitingView.stopAnimation()
            return
        }
        NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_SUCCESS", comment: ""))
        let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling-1)", listProjectType: .ownedByUser, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
        shouldListJoinedProjects = false
        tempOwnerProjects.removeAll()
        projectService?.listProject(filter: listFilter)
    }
    
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        if error == nil {
            inviteMemberAlreadyInProjectTips(alreadyInvited: alreadyInvited!, nowInvited: nowInvited!, alreadyMembers: alreadyMembers!)
        }else{
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
        waitingView.stopAnimation()
    }
    
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?) {
        waitingView.stopAnimation()
        if let _ = error {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("HOME_BOTTOM_DECLINE", comment: ""))
            return
        }
        if let index = tempPendingInvitations.firstIndex(of: invitation) {
            tempPendingInvitations.remove(at: index)
            collectionView.pendingInvitationsList = tempPendingInvitations
            collectionView.reloadCollectionView()
        }
    }
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?) {
        if let _ = error {
            waitingView.stopAnimation()
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("HOME_BOTTOM_ACCEPT_FAILED", comment: ""))
            return
        }
        
        if let index = tempPendingInvitations.firstIndex(of: invitation) {
            tempPendingInvitations.remove(at: index)
            collectionView.pendingInvitationsList = tempPendingInvitations
        }
        let listFilter = NXListProjectFilter(size: "\(listProjectsNumCeiling)", listProjectType: .userJoined, listProjectOrders: [.lastActionTime(isAscend: false), .name(isAscend: true)])
        shouldListJoinedProjects = false
        tempJoinedProjects.removeAll()
        projectService?.listProject(filter: listFilter)
    }
    private func findProject(id: String) -> NXProject? {
        for project in collectionView.ownerProjectList {
            if project.projectId == id {
                return project
            }
        }
        for project in collectionView.joinedProjectList {
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

//MARK: NXScrollWheelCollectionViewDelegate
extension NXHomeBottomView: NXScrollWheelCollectionViewDelegate {
    func onScrollWheel(event: NSEvent) {
        scrollWheel(with: event)
    }
}

//MARK: NXHomeProjectViewDelegate
extension NXHomeBottomView: NXHomeProjectViewDelegate {
    func onAccept(invitation: NXProjectInvitation) {
        waitingView.frame = bounds
        waitingView.startAnimation()
        projectService?.acceptInvitation(invitation: invitation)
        
    }
    func onDecline(invitation: NXProjectInvitation) {
        declineInvitation = invitation
        let vc = NXDeclineInvitationVC()
        vc.delegate = self
        NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
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
        waitingView.frame = bounds
        waitingView.startAnimation()
        projectService?.projectInvitation(project: project, members: members)
    }
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String) {
        let project = NXProject()
        project.name = title
        project.projectDescription = description
        project.invitationMsg = invitationMsg
        waitingView.frame = bounds
        waitingView.startAnimation()
        projectService?.createProject(project: project, invitedEmails: emailArray)
    }
    func onShowAllProjects() {
        delegate?.showAllProjects()
    }
}

extension NXHomeBottomView: NXDeclineInvitationVCDelegate {
    func onDecline(reason: String) {
        waitingView.frame = bounds
        waitingView.startAnimation()
        projectService?.declineInvitation(invitation: declineInvitation, declineReason: reason)
    }
}

extension NXHomeBottomView: NXProjectActivateViewDelegate {
    func onActivate() {
        delegate?.activateProject()
    }
}
