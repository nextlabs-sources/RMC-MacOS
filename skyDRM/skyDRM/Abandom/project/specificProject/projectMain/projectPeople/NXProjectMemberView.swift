//
//  NXProjectMemberView.swift
//  skyDRM
//
//  Created by xx-huang on 28/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectMemberView: NSView {

    @IBOutlet weak var NXProjectMemberCollectionView: NSCollectionView!
    
    @IBOutlet weak var NXSearchField: NSSearchField!
    @IBOutlet weak var popUpButton: NSPopUpButton!
    
    @IBOutlet weak var invitebutton: NSButton!
    
    fileprivate var waitView: NXWaitingView!
    fileprivate var shouldListMembers = false
    fileprivate var isGettingData = false
    
    fileprivate var projectInfo = NXProject()
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var projectMemberList: [NXProjectMember] = [NXProjectMember]()
    fileprivate var pendingInvitationList: [NXProjectInvitation] = [NXProjectInvitation]()
    
    fileprivate var sectionTitle = [String]()
    
    fileprivate struct Constant {
        static let cvHeaderItemId = "NXProjectDescriptionHeader"
        static let cvSectionItem = "NXSpecificProjectTitlePopupTitleSectionItem"
        
        static let itemWidth: CGFloat = 220
        static let itemHeight: CGFloat = 120
        static let standardInterval: CGFloat = 10
    }

    fileprivate var backUpMemberData:[NXProjectMember] = [NXProjectMember]()
    fileprivate var backUpPendingMemberData:[NXProjectInvitation] = [NXProjectInvitation]()
    
    private var infoConext = 0
    
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = BK_COLOR.cgColor
        self.projectInfo = NXSpecificProjectData.shared.getProjectInfo().copy() as! NXProject
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        waitView = NXCommonUtils.createWaitingView(superView: self)
        waitView.isHidden = true
        
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        
        NXProjectMemberCollectionView.layer?.backgroundColor = BK_COLOR.cgColor
        configureCollectionView()
        
        sectionTitle = ["Active", "Pending"]
        
        getData()
        configureInviteButton()
        
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
    func focusSearchField() {
        NXSearchField.selectText(nil)
        NXSearchField.currentEditor()?.selectedRange = NSMakeRange(0, NXSearchField.stringValue.count)
    }
    func configureInviteButton()
    {
        invitebutton.title = "Invite"
        invitebutton.wantsLayer = true
        invitebutton.layer?.backgroundColor = GREEN_COLOR.cgColor
        invitebutton.layer?.cornerRadius = 5
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        
        let resendTitleAttr = NSMutableAttributedString(attributedString: invitebutton.attributedTitle)
        resendTitleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, invitebutton.title.count))
        invitebutton.attributedTitle = resendTitleAttr
    }
    
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 136.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 10.0
        flowLayout.minimumLineSpacing = 10.0
        NXProjectMemberCollectionView.collectionViewLayout = flowLayout
    }
    
    @IBAction func onTapInviteButton(_ sender: Any) {
        let vc = NXProjectInviteVC()
        vc.delegate = self
        vc.projectInfo = projectInfo
        NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(vc)
        
    }
    
    fileprivate func updateData(searchString:String){
        var predicate:NSPredicate = NSPredicate()
        var pendingPredicate:NSPredicate = NSPredicate()
        let tempSearchData:NSMutableArray = (backUpMemberData as NSArray).mutableCopy() as! NSMutableArray
        let tempPendingSearchData:NSMutableArray = (backUpPendingMemberData as NSArray).mutableCopy() as! NSMutableArray
        
        if searchString.isEmpty
        {
            self.projectMemberList = backUpMemberData
            self.pendingInvitationList = backUpPendingMemberData
        }
        else
        {
            predicate = NSPredicate(format: "displayName contains[cd] %@ OR email contains[cd] %@ ", searchString,searchString)
            pendingPredicate = NSPredicate(format: "inviteeEmail contains[cd] %@",searchString,searchString)
            tempSearchData.filter(using: predicate)
            tempPendingSearchData.filter(using: pendingPredicate)
        }
        
        projectMemberList.removeAll()
        pendingInvitationList.removeAll()
        
        for member in tempSearchData {
            projectMemberList.append(member as! NXProjectMember)
        }
        
        for pendingMember in tempPendingSearchData {
            pendingInvitationList.append(pendingMember as! NXProjectInvitation)
        }
        
        NXProjectMemberCollectionView.reloadData()
    }
    

    @IBAction func onClickSearchButton(_ sender: Any) {
        // For Search people
        let searchString:String = NXSearchField.stringValue
        self.updateData(searchString: searchString)
    }

    @IBAction func menuItemSelected(_ sender: Any) {
        let currentSelectedMenuTittle:String = (popUpButton.selectedItem?.title)!
        
        switch currentSelectedMenuTittle {
            
        case "Z-A":
            
            var sortedArray = NSMutableArray()
            sortedArray = (projectMemberList as NSArray).mutableCopy() as! NSMutableArray
            let sort = NSSortDescriptor(key: "displayName", ascending: false,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            sortedArray.sort(using:[sort])
            
            projectMemberList.removeAll()
            projectMemberList = sortedArray.copy() as! [NXProjectMember]
            
            var sortedPendingArray = NSMutableArray()
            sortedPendingArray = (pendingInvitationList as NSArray).mutableCopy() as! NSMutableArray
            let sortPending = NSSortDescriptor(key: "inviteeEmail", ascending: false,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            sortedPendingArray.sort(using:[sortPending])
            pendingInvitationList.removeAll()
            pendingInvitationList = sortedPendingArray.copy() as! [NXProjectInvitation]

        case "Time Ascending":
            
            let sortedMemberArray:[NXProjectMember] = projectMemberList.sorted{$0.creationTime<$1.creationTime}
            projectMemberList.removeAll()
            projectMemberList = sortedMemberArray
            
            let sortedPendingMemberArray:[NXProjectInvitation] = pendingInvitationList.sorted{$0.inviteTime<$1.inviteTime}
            pendingInvitationList.removeAll()
            pendingInvitationList = sortedPendingMemberArray
            
        case "Time Descending":
            
            let sortedMemberArray:[NXProjectMember] = projectMemberList.sorted{$0.creationTime>$1.creationTime}
            projectMemberList.removeAll()
            projectMemberList = sortedMemberArray
            
            let sortedPendingMemberArray:[NXProjectInvitation] = pendingInvitationList.sorted{$0.inviteTime>$1.inviteTime}
            pendingInvitationList.removeAll()
            pendingInvitationList = sortedPendingMemberArray
            
        default:
            
            var sortedArray = NSMutableArray()
            sortedArray = (projectMemberList as NSArray).mutableCopy() as! NSMutableArray
            let sort = NSSortDescriptor(key: "displayName", ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            sortedArray.sort(using:[sort])
            
            projectMemberList.removeAll()
            projectMemberList = sortedArray.copy() as! [NXProjectMember]
            
            var sortedPendingArray = NSMutableArray()
            sortedPendingArray = (pendingInvitationList as NSArray).mutableCopy() as! NSMutableArray
            let sortPending = NSSortDescriptor(key: "inviteeEmail", ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            sortedPendingArray.sort(using:[sortPending])
            
            pendingInvitationList.removeAll()
            pendingInvitationList = sortedPendingArray.copy() as! [NXProjectInvitation]
        }
        
        NXProjectMemberCollectionView.reloadData()
    }
    
    fileprivate func getData(){
        if isGettingData {
            return
        }
        isGettingData = true
        let filter = NXProjectPendingInvitationFilter(page: "1", size: "", orderBy: [NXProjectMemberSortType.displayName(isAscend: true)], q:[NXProjectSearchFieldType.name], searchString:"")
        waitView.isHidden = false
        shouldListMembers = true
        projectService?.listPendingInvitationForProject(project: projectInfo, filter: filter)
    }
    
}

extension NXProjectMemberView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        if pendingInvitationList.count > 0 {
            return 2
        }
        else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0{
            return projectMemberList.count
        }else{
            return pendingInvitationList.count
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        if indexPath.section == 0 {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXProjectMemberCellItem"), for: indexPath)
            guard let collectionViewItem = item as? NXProjectMemberCellItem else{
                return item
            }
            
            collectionViewItem.memberInfo = projectMemberList[indexPath.item]
            collectionViewItem.delegate = self
            
            // Add owner icon
            collectionViewItem.ownerImageView.isHidden = (projectInfo.owner?.userId == projectMemberList[indexPath.item].userId) ? false: true
            
            return collectionViewItem
        }
        else {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXProjectMemberCellItem"), for: indexPath)
            guard let collectionViewItem = item as? NXProjectMemberCellItem else{
                return item
            }
            
            collectionViewItem.invitationInfo = pendingInvitationList[indexPath.item]
            collectionViewItem.delegate = self
            collectionViewItem.ownerImageView.isHidden = true
            return collectionViewItem
        }
    }
    
    internal func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier:  NSUserInterfaceItemIdentifier(rawValue: Constant.cvHeaderItemId), for: indexPath) as! NXProjectDescriptionHeader
        view.label = (sectionTitle[indexPath.section], "")
        return view
    }

}

extension NXProjectMemberView:NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int)->NSSize{
        return NSSize(width: 1000, height: 40)
    }
}

extension NXProjectMemberView:NXProjectMemberCellItemDelegate{
    
    func onClickMemberCellItem(memberModel:NXProjectMember?,pendingInvitation:NXProjectInvitation?,isInvitation:Bool) {
        if isInvitation {
            let vc = NXProjectPendingInvitationDetailViewController()
            vc.memberInfo = memberModel
            vc.project = projectInfo
            vc.delegate = self
            vc.projectPendingInvitation = pendingInvitation
            NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(vc)
        }
        else {
            let vc = NXProjectMemberDetailViewController()
            vc.memberInfo = memberModel
            vc.project = projectInfo
            vc.delegate = self
            
            NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(vc)
        }
    }
}

extension NXProjectMemberView : NXProjectAdapterDelegate {
    func listMemberFinish(projectId: String, filter: NXProjectMemberFilter, memberList: [NXProjectMember]?, error: Error?) {
        projectMemberList.removeAll()
        backUpMemberData.removeAll()
        projectInfo.projectMembers?.removeAll()
        waitView.isHidden = true
        if let memberList = memberList {
            for item in memberList {
                projectMemberList.append(item)
                projectInfo.projectMembers?.append(item)
            }
            backUpMemberData = projectMemberList
        }
        projectInfo.totalMembers = projectMemberList.count
        NXSpecificProjectData.shared.setProjectInfo(info: projectInfo.copy() as! NXProject)

        NXProjectMemberCollectionView.reloadData()
        isGettingData = false
    }
    
    func listPendingInvitationForProjectFinish(projectId: String, filter: NXProjectPendingInvitationFilter, pendingList: [NXProjectInvitation]?, error: Error?) {
        pendingInvitationList.removeAll()
        backUpPendingMemberData.removeAll()
        
        if let pendingList = pendingList {
            for item in pendingList {
                pendingInvitationList.append(item)
            }
            backUpPendingMemberData = pendingInvitationList
        }
        if shouldListMembers {
            let filter = NXProjectMemberFilter(page: "1", size: "", orderBy: [NXProjectMemberSortType.displayName(isAscend: true)], picture:true,q:[NXProjectSearchFieldType.name],searchString:"")
            projectService?.listMember(project: projectInfo, filter:filter)
        }
        else {
            waitView.isHidden = true
            NXProjectMemberCollectionView.reloadData()
        }
    }
    
    func projectInvitationFinish(projectId: String, invitedEmails: [String], alreadyInvited: [String]?, nowInvited: [String]?, alreadyMembers: [String]?, error: Error?) {
        if error == nil {
            let filter1 = NXProjectPendingInvitationFilter(page: "1", size: "", orderBy: [NXProjectMemberSortType.displayName(isAscend: true)],q:[NXProjectSearchFieldType.name],searchString:"")
            shouldListMembers = false
            projectService?.listPendingInvitationForProject(project: projectInfo, filter: filter1)
            
            inviteMemberAlreadyInProjectTips(alreadyInvited: alreadyInvited!, nowInvited: nowInvited!, alreadyMembers: alreadyMembers!)
        }
        else {
            waitView.isHidden = true
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
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

extension NXProjectMemberView: NXProjectMemberDetailVCDelegate {
    func removeMemberFromProjectFinished(error:Error?, member: NXProjectMember) {
        if error == nil {
            for (index, item) in projectMemberList.enumerated() {
                if item.email == member.email {
                    projectMemberList.remove(at: index)
                    break
                }
            }
            
            if let members = projectInfo.projectMembers {
                for (index, memberItem) in members.enumerated() {
                    if member.userId == memberItem.userId  {
                        projectInfo.projectMembers!.remove(at: index)
                    }
                }
                projectInfo.totalMembers = projectInfo.projectMembers!.count
                NXSpecificProjectData.shared.setProjectInfo(info: projectInfo.copy() as! NXProject)
            }
            NXProjectMemberCollectionView.reloadData()
            
            NXToastWindow.sharedInstance?.toast(String(format: NSLocalizedString("PROJECT_MEMBER_REMOVE_SUCCESS", comment: ""), member.displayName!))
        }
        else {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("PROJECT_MEMBER_REMOVE_FAILED", comment: ""))
        }
    }
}

extension NXProjectMemberView : NXProjectPendingInvitationDetailVCDelegate {
    func resendInvitationFinished(error:Error?) {
        if error == nil {
             NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_RESEND_SUCCESS", comment: ""))
        }
        else {
             NXToastWindow.sharedInstance?.toast(NSLocalizedString("INVITE_FAILED", comment: ""))
        }
    }
    
    func revokeInvitationFinished(invitation: NXProjectInvitation, error:Error?) {
        if error == nil {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("REVOKE_SUCCESS", comment: ""))
            
            for (index, item) in pendingInvitationList.enumerated() {
                if item.inviteeEmail == invitation.inviteeEmail {
                    pendingInvitationList.remove(at: index)
                    break
                }
            }
            
            NXProjectMemberCollectionView.reloadData()
        }
        else {
              NXToastWindow.sharedInstance?.toast(NSLocalizedString("REVOKE_FAILED", comment: ""))
        }
    }
}

extension NXProjectMemberView: NXProjectInviteDelegate{
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
        waitView.isHidden = false
        projectService?.projectInvitation(project: project, members: members)
    }
}
