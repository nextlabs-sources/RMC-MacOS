//
//  NXSpecificProjectHomePeopleView.swift
//  skyDRM
//
//  Created by helpdesk on 2/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomePeopleView: NSView {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var waitView: NSProgressIndicator!
    @IBOutlet weak var inviteBtn: NSButton!
    @IBOutlet weak var viewAllPeopleBtn: NSButton!
    
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var profile: NXLProfile?
    fileprivate var projectInfo = NXProject()
    
    weak var delegate: NXSpecificProjectHomePeopleDelegate?
    
    private var infoConext = 0
    fileprivate var isGettingData = false
    
    struct Constant {
        static let collectionViewItemIdentifier = "NXSpecificProjectHomePeopleItemView"
        
        static let itemHeight: CGFloat = 60
        static let standardInterval: CGFloat = 0
        
        static let maxDisplayCount = 4
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        collectionView?.collectionViewLayout?.invalidateLayout()
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        profile = NXLoginUser.sharedInstance.nxlClient?.profile
        if let profile = profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        
        projectInfo = NXSpecificProjectData.shared.getProjectInfo()
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        
        collectionView.layer?.backgroundColor = WHITE_COLOR.cgColor
        configureCollectionView()
        
        inviteBtn.title = NSLocalizedString("PROJECT_PEOPLE_INVITE_BUTTON", comment: "")        
        inviteBtn.wantsLayer = true
        inviteBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        inviteBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: inviteBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, inviteBtn.title.count))
        inviteBtn.attributedTitle = titleAttr
        
        viewAllPeopleBtn.stringValue = NSLocalizedString("PROJECT_PEOPLE_VIEW_BUTTON", comment: "")
        if let textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0) {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            let titleAttr = NSMutableAttributedString(attributedString: viewAllPeopleBtn.attributedTitle)
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, viewAllPeopleBtn.title.count))
            viewAllPeopleBtn.attributedTitle = titleAttr
        }
        self.wantsLayer = true
        self.layer?.backgroundColor = WHITE_COLOR.cgColor
        getData()
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            let gProjectInfo = NXSpecificProjectData.shared.getProjectInfo()
            self.projectInfo = gProjectInfo.copy() as! NXProject
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: self.bounds.width, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        collectionView.collectionViewLayout = flowLayout
        
        collectionView.delegate = self
    }
    
    fileprivate func getData(){
        if isGettingData {
            return
        }
        isGettingData = true
        waitView.isHidden = false
        waitView.startAnimation(nil)
        let filter = NXProjectMemberFilter(page: "1", size: "\(Constant.maxDisplayCount)", orderBy: [NXProjectMemberSortType.displayName(isAscend: true)], picture: true, q: [NXProjectSearchFieldType.name],searchString:"")
        projectService?.listMember(project: projectInfo, filter: filter)
    }
    
    @IBAction func invitePeople(_ sender: Any) {
        invitePeople()
    }
    
    @IBAction func viewAllPeople(_ sender: Any) {
        delegate?.viewAllPeople()
    }
    func invitePeople() {
        let vc = NXProjectInviteVC()
        vc.delegate = self
        vc.projectInfo = projectInfo
        NSApplication.shared.keyWindow?.windowController?.contentViewController?.presentAsModalWindow(vc)
    }
}

extension NXSpecificProjectHomePeopleView:NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(projectInfo.totalMembers, Constant.maxDisplayCount)
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem{
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        guard let collectionViewItem = viewItem as? NXSpecificProjectHomePeopleItemView else{
            return viewItem
        }
        if let members = projectInfo.projectMembers,
            indexPath.item < members.count {
            collectionViewItem.memberInfo = members[indexPath.item]
        }
        collectionViewItem.delegate = self
        
        return collectionViewItem
    }
}
extension NXSpecificProjectHomePeopleView:NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}

extension NXSpecificProjectHomePeopleView:NXProjectAdapterDelegate{
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        if error == nil {
            inviteMemberAlreadyInProjectTips(alreadyInvited: alreadyInvited!, nowInvited: nowInvited!, alreadyMembers: alreadyMembers!)
        }else{
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
    }
    
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?){
        waitView.stopAnimation(self)
        waitView.isHidden = true
        
        guard let memberList = memberList else{
            return
        }
        
        projectInfo.projectMembers?.removeAll()
        var projectMemberList = [NXProjectMember]()
        for item in memberList {
            projectMemberList.append(item)
        }
        projectMemberList.sort(by: { item1, item2 in !item1.creationTime.isLess(than: item2.creationTime) })
        
        collectionView.reloadData()
        projectInfo.projectMembers = projectMemberList
        projectInfo.totalMembers = projectMemberList.count
        NXSpecificProjectData.shared.setProjectInfo(info: self.projectInfo.copy() as! NXProject)
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

extension NXSpecificProjectHomePeopleView:NXProjectInviteDelegate{
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
}

extension NXSpecificProjectHomePeopleView:NXSpecialProjectHomePeopleItemDelegate{
   func onClickPeopleCellItem(memberModel:NXProjectMember?) {
        let vc = NXProjectMemberDetailViewController()
        vc.memberInfo = memberModel
        vc.project = projectInfo
        vc.delegate = self
    
    NSApplication.shared.keyWindow?.windowController?.contentViewController?.presentAsModalWindow(vc)
   }
}

extension NXSpecificProjectHomePeopleView : NXProjectMemberDetailVCDelegate {
    func removeMemberFromProjectFinished(error:Error?, member: NXProjectMember) {
        if error == nil {
            self.getData()
            NXToastWindow.sharedInstance?.toast(String(format: NSLocalizedString("PROJECT_HOME_MEMBER_REMOVE_SUCCESS", comment: ""), member.displayName!))
        }
        else
        {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("PROJECT_HOME_MEMBER_REMOVE_FAILED", comment: ""))
        }
    }
}

extension NXSpecificProjectHomePeopleView:NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath)->NSSize{
        
        return NSSize(width: self.bounds.width, height: Constant.itemHeight)
    }
}

