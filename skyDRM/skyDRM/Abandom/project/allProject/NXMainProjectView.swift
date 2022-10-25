//
//  NXMainProjectView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/3.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXMainProjectViewDelegate: NSObjectProtocol {
    func gobackHome()
    func activateProject()
}

class NXMainProjectView: NSView {

    @IBOutlet weak var collectionView: NXHomeProjectView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var titleView: NSView!
    @IBOutlet weak var homeBtn: NSButton!
    @IBOutlet weak var customView: NSView!
    
    @IBOutlet weak var outsideScrollView: NSScrollView!
    @IBOutlet weak var accountNameLbl: NSTextField!
    @IBOutlet weak var accountIconView: NXCircleText!
    @IBOutlet weak var pendingStackView: NSStackView!
    @IBOutlet weak var createByMeStackView: NSStackView!
    @IBOutlet weak var invitedByOthersStackView: NSStackView!
    
    @IBOutlet weak var documentHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var activateHeightConstraint: NSLayoutConstraint!

    private var activateView: NXProjectActivateView?
    
    private var ownerProjectListContext = 0
    private var joinedProjectListContext = 0
    private var pendingInvitationsContext = 0
    private var specificProjectInfoContext = 0
    
    fileprivate let waitingView = NXProgressIndicatorView()
    fileprivate var isRetrievingNetworkData = false
    fileprivate var isRefreshTriggeredBySelf = false
    fileprivate var showActivateView = false
    
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var declineInvitation = NXProjectInvitation()
    
    fileprivate var tempPendingInvitations = [NXProjectInvitation]()
    fileprivate var tempOwnerProjects = [NXProject]()
    fileprivate var tempJoinedProjects = [NXProject]()
    
    fileprivate var totalOwnerProjects: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.updateTotalDisplay(with: self.createByMeStackView, totalNumb: self.totalOwnerProjects)
            }
        }
    }
    
    fileprivate var totalJoinedProjects: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.updateTotalDisplay(with: self.invitedByOthersStackView, totalNumb: self.totalJoinedProjects)
            }
            
        }
    }
    fileprivate var totalPendingInvitations: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.updateTotalDisplay(with: self.pendingStackView, totalNumb: self.totalPendingInvitations)
            }
        }
    }
    
    fileprivate let activateHeightConst: CGFloat = 80
    weak var delegate: NXMainProjectViewDelegate?
    override var isHidden: Bool {
        didSet {
            if isHidden == false {
                showAccountInfo()
            }
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "pendingInvitationsList")
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "ownerProjectList", context: &ownerProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.removeObserver(self, forKeyPath: "joinedProjectList", context: &joinedProjectListContext)
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
        
        self.collectionView.removeObserver(self, forKeyPath: #keyPath(frame))
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "ownerProjectList", options: .new, context: &ownerProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "joinedProjectList", options: .new, context: &joinedProjectListContext)
        NXLoginUser.sharedInstance.projectStorage.addObserver(self, forKeyPath: "pendingInvitationsList", options: .new, context: &pendingInvitationsContext)
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &specificProjectInfoContext)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        titleView.wantsLayer = true
        titleView.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        let attribute = [NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#ffffff", alpha: 1.0)]
        homeBtn.attributedTitle = NSAttributedString(string: homeBtn.title, attributes: attribute as [NSAttributedString.Key : Any] )
        
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = NSColor.white.cgColor
        collectionView.collectionDelegate = self
        collectionView.scrollDelegate = self
        
        addSubview(waitingView)
        
        activateView = NXCommonUtils.createViewFromXib(xibName: "NXProjectActivateView", identifier: "projectActivateView", frame: nil, superView: customView) as? NXProjectActivateView
        activateView?.delegate = self
        
        activateHeightConstraint.constant = 0
        
        showAccountInfo()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(frame),
            let newFrame = change?[.newKey] as? NSRect {
            if scrollView.frame.height == newFrame.height {
                return
            }
            
            collectionView.removeObserver(self, forKeyPath: #keyPath(frame))
            updateDocumentView(with: newFrame, oldFrame: self.scrollView.frame)
            return
        }
        
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
        storage.joinedProjectList = tempJoinedProjects
        storage.pendingInvitationsList = tempPendingInvitations
        storage.ownerProjectList = tempOwnerProjects
        isRefreshTriggeredBySelf = true
        NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
    }
    func doWork(){
        updateFromNetwork()
    }
    func updateAccountName() {
        showAccountInfo()
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
    
    @IBAction func onGoHome(_ sender: Any) {
        delegate?.gobackHome()
    }

    func syncProjects() {
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

    deinit {
        debugPrint(#function + self.className)
    }

    fileprivate func updateFromNetwork(){
        if isRetrievingNetworkData {
            return
        }
        isRetrievingNetworkData = true
        waitingView.frame = bounds
        waitingView.startAnimation()
        projectService?.listPendingInvitationForUser()
        
        // get total number of create by me and invited by others project
    }
    
    fileprivate func refreshOneItem(project: NXProject) {
        DispatchQueue.main.async {
            self.collectionView.addObserver(self, forKeyPath: #keyPath(frame), options: [.old, .new], context: nil)
            self.collectionView.reloadCollectionItem(project: project)
        }
    }
    fileprivate func updateUI() {
        collectionView.pendingInvitationsList = tempPendingInvitations
        collectionView.joinedProjectList = tempJoinedProjects
        collectionView.ownerProjectList = tempOwnerProjects
        collectionView.totalOwnerProjects = totalOwnerProjects
        collectionView.totalJoinedProjects = totalJoinedProjects
        DispatchQueue.main.async {
            //activate
            if self.tempOwnerProjects.count == 0 && self.showActivateView {
                self.activateHeightConstraint.constant = 80
            } else {
                self.activateHeightConstraint.constant = 0
            }
            
            self.collectionView.showViewAllBtn = false
            
            self.collectionView.addObserver(self, forKeyPath: #keyPath(frame), options: [.old, .new], context: nil)
            self.collectionView.reloadCollectionView()
        }
    }
    
    private func showAccountInfo() {
        guard let profile = NXLoginUser.sharedInstance.nxlClient?.profile else {
                return
        }
        
        accountNameLbl.stringValue = profile.userName
        if let _ = NSImage(base64String: profile.avatar) {
            debugPrint("display image")
        } else {
            if let displayName = profile.displayName ?? profile.userName {
                let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
                accountIconView.text = abbrevStr
                accountIconView.extInfo = profile.email
                let firstLetter = String(abbrevStr[abbrevStr.startIndex]).lowercased()
                if let colorHex = NXCommonUtils.circleViewBKColor[firstLetter],
                    let color = NSColor(colorWithHex: colorHex, alpha: 1.0) {
                    accountIconView.backgroundColor = color
                }
                accountIconView.delegate = self
            }
            
        }
    }
    
    private func updateDocumentView(with newFrame: NSRect, oldFrame: NSRect) {
        if let documentView = outsideScrollView.documentView {
            let newHeight = documentView.frame.height + newFrame.height - oldFrame.height
            documentHeightConstraint.constant = newHeight
            
        }
    }
    
    private func updateTotalDisplay(with stackView: NSView, totalNumb: Int) {
        if let numbLbl = (stackView.subviews.filter() { $0.tag == 0 }).first as? NSTextField {
            numbLbl.stringValue = String(totalNumb)
        }
        
        if let projectLbl = (stackView.subviews.filter() { $0.tag == 1 }).first as? NSTextField {
            projectLbl.stringValue = (totalNumb > 1) ? "Projects" : "Project"
        }
    }
    
    @IBAction func clickPendingInvitation(_ sender: Any) {
        _ = scrollViewToSection(with: 0)
    }
    
    @IBAction func clickCreatedByMe(_ sender: Any) {
        _ = scrollViewToSection(with: 1)
    }
    
    @IBAction func clickInvitedByOthers(_ sender: Any) {
        _ = scrollViewToSection(with: 2)
    }
    
    private func scrollViewToSection(with index: Int) -> Bool {
        if index == 0 {
            if totalPendingInvitations == 0 {
                return false
            }
        } else if index == 1 {
            if totalOwnerProjects == 0 {
                return false
            }
        } else if index == 2 {
            if totalJoinedProjects == 0 {
                return false
            }
        }
        
        let transformIndexToSection: (Int) -> (Int) = {
            index in
            var section = index
            if index == 1 {
                if self.totalPendingInvitations == 0 {
                    section = 0
                }
            } else if index == 2 {
                if self.totalPendingInvitations == 0 && self.totalOwnerProjects == 0 {
                    section = 0
                } else if self.totalPendingInvitations == 0 || self.totalOwnerProjects == 0 {
                    section = 1
                }
            }
            
            return section
        }
        let section = transformIndexToSection(index)
        
        let sectionHeight: CGFloat = 40
        let firstIndexPath = IndexPath(item: 0, section: section)
        let lastIndexPath = IndexPath(item: collectionView.numberOfItems(inSection: section) - 1, section: section)
        guard
            let firstItem = collectionView.item(at: firstIndexPath),
            let lastItem = collectionView.item(at: lastIndexPath)
            else { return false }
        
        let x = scrollView.frame.origin.x
        let y = firstItem.view.frame.origin.y - sectionHeight
        let width = scrollView.frame.width
        let height = lastItem.view.frame.origin.y - firstItem.view.frame.origin.y + firstItem.view.frame.height + sectionHeight
        let size = CGSize(width: width, height: height)
        let frame = NSRect(origin: CGPoint(x: x, y: y), size: size)
        
        let isScrollSucess = scrollView.scrollToVisible(frame)
        
        return isScrollSucess
    }
}

extension NXMainProjectView: NXProjectAdapterDelegate{
    func listProjectFinish(filter: NXListProjectFilter, totalProjects: Int, projectList: [NXProject]?, error: Error?){
        waitingView.stopAnimation()
        
        showActivateView = error == nil ? true : false
        guard let projectList = projectList else{
            return
        }
        tempOwnerProjects.removeAll()
        tempJoinedProjects.removeAll()
        
        for item in projectList {
            if item.ownedByMe {
                tempOwnerProjects.append(item)
            }else{
                tempJoinedProjects.append(item)
            }
        }
        
        totalOwnerProjects = tempOwnerProjects.count
        totalJoinedProjects = tempJoinedProjects.count
        
        let storage = NXProjectStorage()
        storage.joinedProjectList = tempJoinedProjects
        storage.pendingInvitationsList = tempPendingInvitations
        storage.ownerProjectList = tempOwnerProjects
        isRefreshTriggeredBySelf = true
        NXLoginUser.sharedInstance.updateprojectStorage(projectStorage: storage)
        updateUI()
        isRetrievingNetworkData = false
    }
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        if error != nil {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_FAIL", comment: ""))
            waitingView.stopAnimation()
            return
        }
        NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_SUCCESS", comment: ""))
        let listFilter = NXListProjectFilter(listProjectType: .allProject, listProjectOrders: [])
        projectService?.listProject(filter: listFilter)
        
        totalOwnerProjects += 1
    }
    
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        waitingView.stopAnimation()
        if error == nil {
            inviteMemberAlreadyInProjectTips(alreadyInvited: alreadyInvited!, nowInvited: nowInvited!, alreadyMembers: alreadyMembers!)
        }else{
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
    }
    
    func listPendingInvitationForUserFinish(pendingList: [NXProjectInvitation]?, error: Error?) {
        tempPendingInvitations.removeAll()
        if var pendingList = pendingList {
            pendingList.sort(by: {
                return $0.inviteTime > $1.inviteTime
            })
            tempPendingInvitations = pendingList
            totalPendingInvitations = tempPendingInvitations.count
        }
        let listFilter = NXListProjectFilter(listProjectType: .allProject, listProjectOrders: [])
        projectService?.listProject(filter: listFilter)
    }
    
    func declineInvitationFinish(invitation: NXProjectInvitation, error: Error?) {
        waitingView.stopAnimation()
        if let _ = error {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("PROJECT_ALL_DECLINE_FAILED", comment: ""))
            return
        }
        if let index = tempPendingInvitations.firstIndex(of: invitation) {
            tempPendingInvitations.remove(at: index)
            totalPendingInvitations = tempPendingInvitations.count
            collectionView.pendingInvitationsList = tempPendingInvitations
            collectionView.showViewAllBtn = false
            
            self.collectionView.addObserver(self, forKeyPath: #keyPath(frame), options: [.old, .new], context: nil)
            collectionView.reloadCollectionView()
        }
    }
    func acceptInvitationFinish(invitation: NXProjectInvitation, projectId: String?, error: Error?) {
        if let _ = error {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("PROJECT_ALL_ACCEPT_FAILED", comment: ""))
            waitingView.stopAnimation()
            return
        }
        if let index = tempPendingInvitations.firstIndex(of: invitation) {
            tempPendingInvitations.remove(at: index)
            totalPendingInvitations = tempPendingInvitations.count
            totalJoinedProjects += 1
        }
        let listFilter = NXListProjectFilter(listProjectType: .allProject, listProjectOrders: [])
        projectService?.listProject(filter: listFilter)
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

//MARK: NXHomeProjectViewDelegate
extension NXMainProjectView: NXHomeProjectViewDelegate {
    func onAccept(invitation: NXProjectInvitation) {
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
        waitingView.startAnimation()
        projectService?.projectInvitation(project: project, members: members)
    }
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String) {
        let project = NXProject()
        project.name = title
        project.projectDescription = description
        project.invitationMsg = invitationMsg
        waitingView.startAnimation()
        projectService?.createProject(project: project, invitedEmails: emailArray)
    }
    func onShowAllProjects() {
    }
}

extension NXMainProjectView: NXScrollWheelCollectionViewDelegate {
    func onScrollWheel(event: NSEvent) {
        outsideScrollView.scrollWheel(with: event)
    }
}

extension NXMainProjectView: NXDeclineInvitationVCDelegate {
    func onDecline(reason: String) {
        waitingView.startAnimation()
        projectService?.declineInvitation(invitation: declineInvitation, declineReason: reason)
    }
}

extension NXMainProjectView: NXProjectActivateViewDelegate {
    func onActivate() {
        delegate?.activateProject()
    }
}

extension NXMainProjectView: MouseEventDelegate {
    func mouseEvent(entered event: NSEvent) {}
    func mouseEvent(exited event: NSEvent) {}
    func mouseEvent(down event: NSEvent) {
        if let viewController = self.window?.contentViewController as? ViewController {
            viewController.homeOpenAccountVC()
        }
    }
}
