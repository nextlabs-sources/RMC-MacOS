//
//  NXHomeProjectView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/2.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeProjectViewDelegate: NSObjectProtocol {
    func onAccept(invitation: NXProjectInvitation)
    func onDecline(invitation: NXProjectInvitation)
    func onInvite(projectId: String, emailArray: [String], invitationMsg: String)
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String)
    func onShowAllProjects()
    func beforeSelectItem(projectInfo: NXProject)
}
extension NXHomeProjectViewDelegate {
    func beforeSelectItem(projectInfo: NXProject) {}
}

class NXHomeProjectView: NXScrollWheelCollectionView {
    enum SectionType {
        case pending
        case owner
        case joined
    }
    
    fileprivate var sectionDisplayTitle = [(String, String)]()
    fileprivate var sectionExpandNumArray = [Int]()
    fileprivate var sectionDisplayNumArray = [(SectionType, Int)]()
    fileprivate var sectionExpandStatusArray = [Bool]()
    fileprivate var sectionNumber = 0
    
    fileprivate struct Constant {
        static let cvHeaderItemId = "NXProjectDescriptionHeader"
        static let cvNewItemId = "NXCreateNewProjectItem"
        static let cvPendingInvitationsItemId = "NXPendingInvitationsItem"
        static let cvCreateItemId = "NXProjectCreateByMeItem"
        static let cvOtherItemId = "NXProjectCreateByOthersItem"
        static let cvSectionItem = "NXSpecificProjectTitlePopupTitleSectionItem"
    }
    struct UIConstant {
        static let itemWidth: CGFloat = 220
        static let itemHeight: CGFloat = 120
        static let standardInterval: CGFloat = 10
        static let headerWidth: CGFloat = 800
        static let headerHeight: CGFloat = 40
        static let rowSpacing: CGFloat = 20
        
        static let sectionFooterHeight: CGFloat = 5
    }
    weak var collectionDelegate: NXHomeProjectViewDelegate?
    var ownerProjectList: [NXProject] = [NXProject]()
    var joinedProjectList: [NXProject] = [NXProject]() 
    var pendingInvitationsList: [NXProjectInvitation] = [NXProjectInvitation]()
    var totalOwnerProjects: Int = 0
    var totalJoinedProjects: Int = 0
    var showViewAllBtn = true// show/hide viewAll btn
    var hasNewProjectItem = false// flag for SpecificProjectTitlePopupViewController
    fileprivate var newProjectVC: NXNewProjectVC?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            configureCollectionView()
            self.dataSource = self
        }
    }
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 0, left: UIConstant.standardInterval, bottom: 0, right: UIConstant.standardInterval)
        flowLayout.minimumInteritemSpacing = UIConstant.rowSpacing
        flowLayout.minimumLineSpacing = UIConstant.rowSpacing
        flowLayout.headerReferenceSize = NSMakeSize(UIConstant.headerWidth, UIConstant.headerHeight)
        
        flowLayout.footerReferenceSize = NSMakeSize(UIConstant.headerWidth, UIConstant.sectionFooterHeight)
        
        flowLayout.itemSize = NSMakeSize(UIConstant.itemWidth, UIConstant.itemHeight)
        self.collectionViewLayout = flowLayout
    }
}
extension NXHomeProjectView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return sectionNumber
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionDisplayNumArray[section].1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let makePendingInvitationsItem = { [weak self] () -> NSCollectionViewItem in
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.cvPendingInvitationsItemId), for: indexPath)
            guard let pendingInvitationsItem = item as? NXPendingInvitationsItem else {
                return item
            }
            pendingInvitationsItem.projectInvitation =  self?.pendingInvitationsList[indexPath.item]
            pendingInvitationsItem.delegate = self
            return pendingInvitationsItem
        }
        let makeNewProjectItem = { [weak self] () -> NSCollectionViewItem in
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.cvNewItemId), for: indexPath)
            guard let collectionViewItem = item as? NXCreateNewProjectItem else{
                return item
            }
            if let strongSelf = self {
                collectionViewItem.delegate = strongSelf
            }
            return collectionViewItem
        }
        let makeCreateByMeItem = { [weak self] () -> NSCollectionViewItem in
    
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.cvCreateItemId), for: indexPath)
            guard let collectionViewItem = item as? NXProjectCreateByMeItem else{
                return item
            }
            if let strongSelf = self {
                collectionViewItem.delegate = strongSelf
                collectionViewItem.projectInfo = strongSelf.ownerProjectList[indexPath.item - 1]
            }
            
            return collectionViewItem
        }
        let makeCreateByOthersItem = { [weak self] () -> NSCollectionViewItem in
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.cvOtherItemId), for: indexPath)
            guard let collectionViewItem = item as? NXProjectCreateByOthersItem else{
                return item
            }
            if let strongSelf = self {
                
                collectionViewItem.delegate = strongSelf
                collectionViewItem.projectInfo = strongSelf.joinedProjectList[indexPath.item]
            }
            return collectionViewItem
        }
        switch sectionDisplayNumArray[indexPath.section].0 {
        case .pending:
            return makePendingInvitationsItem()
        case .owner:
            if indexPath.item == 0 {
                return makeNewProjectItem()
            }
            else {
                return makeCreateByMeItem()
            }
        case .joined:
            return makeCreateByOthersItem()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.cvHeaderItemId), for: indexPath) as! NXProjectDescriptionHeader
        if let itemNum = getSectionItemTotalNum(section: indexPath.section),
            let itemType = getSectionType(id: indexPath.section) {
            switch itemType {
            case .pending:
                view.setExpandNumber(expandMinNum: sectionExpandNumArray[indexPath.section], displayedNum: itemNum, totalNum: 0)
                view.shouldShowTotalNumber = false
            case .owner:
                view.setExpandNumber(expandMinNum: sectionExpandNumArray[indexPath.section], displayedNum: itemNum, totalNum: totalOwnerProjects)
                view.shouldShowTotalNumber = showViewAllBtn
            case .joined:
                view.setExpandNumber(expandMinNum: sectionExpandNumArray[indexPath.section], displayedNum: itemNum, totalNum: totalJoinedProjects)
                view.shouldShowTotalNumber = showViewAllBtn
                
            }
        }
        view.label = sectionDisplayTitle[indexPath.section]
        view.section = indexPath.section
        view.delegate = self
        view.bExpanded = sectionExpandStatusArray[indexPath.section]
        
        //show first header's "view all projects" button
        view.shouldHideViewBtn = !view.shouldShowTotalNumber
        return view
    }
    
    fileprivate func getSectionId(type: SectionType) -> Int? {
        for (index, item) in sectionDisplayNumArray.enumerated() {
            if type == item.0 {
                return index
            }
        }
        return nil
    }
    
    fileprivate func getSectionType(id: Int) -> SectionType? {
        guard id < sectionDisplayNumArray.count else {
            return nil
        }
        return sectionDisplayNumArray[id].0
    }
    
    fileprivate func getSectionItemTotalNum(section: Int) -> Int? {
        if section < sectionDisplayNumArray.count {
            return sectionDisplayNumArray[section].1
        }
        else {
            return nil
        }
    }
    
    func reloadCollectionView() {
        sectionDisplayTitle.removeAll()
        sectionExpandStatusArray.removeAll()
        sectionExpandNumArray.removeAll()
        sectionDisplayNumArray.removeAll()
        sectionNumber = 0
        if pendingInvitationsList.isEmpty == false {
            sectionDisplayTitle.append((NSLocalizedString("PROJECT_PENDING_INVITATIONS", comment: ""), ""))
            sectionExpandStatusArray.append(false)
            sectionExpandNumArray.append(300)
            sectionDisplayNumArray.append((.pending, min(pendingInvitationsList.count, sectionExpandNumArray[sectionNumber])))
            sectionNumber += 1
        }
        if ownerProjectList.isEmpty == false || hasNewProjectItem {
            sectionDisplayTitle.append((NSLocalizedString("PROJECT_CREATE_BY_ME_PREFIX", comment: ""), NSLocalizedString("PROJECT_CREATE_BY_ME_SUFFIX", comment: "")))
            sectionExpandStatusArray.append(false)
            sectionExpandNumArray.append(300)
            sectionDisplayNumArray.append((.owner, min(ownerProjectList.count + 1, sectionExpandNumArray[sectionNumber])))
            sectionNumber += 1
        }
        if joinedProjectList.isEmpty == false {
            sectionDisplayTitle.append((NSLocalizedString("PROJECT_INVITED_BY_OTHERS_PREFIX", comment: ""), NSLocalizedString("PROJECT_INVITED_BY_OTHERS_SUFFIX", comment: "")))
            sectionExpandStatusArray.append(false)
            sectionExpandNumArray.append(300)
            sectionDisplayNumArray.append((.joined, min(joinedProjectList.count, sectionExpandNumArray[sectionNumber])))
            sectionNumber += 1
        }

        reloadData()
    }
    func reloadCollectionItem(project: NXProject) {
        for (index, item) in ownerProjectList.enumerated() {
            if item == project {
                ownerProjectList[index] = project
                if let sectionId = getSectionId(type: .owner) {
                    let itemIndexs = [IndexPath(item: index + 1, section: sectionId)]
                    reloadItems(at: Set<IndexPath>(itemIndexs))
                }
                return
            }
        }
        for (index, item) in joinedProjectList.enumerated() {
            if item == project {
                joinedProjectList[index] = project
                if let sectionId = getSectionId(type: .joined) {
                    let itemIndexs = [IndexPath(item: index, section: sectionId)]
                    reloadItems(at: Set<IndexPath>(itemIndexs))
                }
                return
            }
        }
    }
    func selectProjectItem(info: NXProject) {
        let vc = NXSpecificProjectWindow.sharedInstance.window?.contentViewController as? NXSpecificProjectViewController
        vc?.initData(projectInfo: info)
        NXSpecificProjectWindow.sharedInstance.showWindow()
    }
}

//MARK: NXProjectHeaderDelegate
extension NXHomeProjectView: NXProjectHeaderDelegate {
    func showCollectItem(section: Int, itemnum: Int, expanded: Bool) {
        sectionDisplayNumArray[section].1 = itemnum
        sectionExpandStatusArray[section] = expanded
        reloadData()
    }
    func createProject() {
        onCreateProjectCreate()
    }
    func viewAllProjects() {
        collectionDelegate?.onShowAllProjects()
    }
}
//MARK: NXPendingInvitationsDelegate
extension NXHomeProjectView: NXPendingInvitationsDelegate {
    func onAccept(invitation: NXProjectInvitation) {
        collectionDelegate?.onAccept(invitation: invitation)
    }
    func onDecline(invitation: NXProjectInvitation) {
        collectionDelegate?.onDecline(invitation: invitation)
    }
}
//MARK: NXCreateByMeDelegate
extension NXHomeProjectView: NXCreateByMeDelegate{
    func onInviteClick(projectInfo: NXProject) {
        let vc = NXProjectInviteVC()
        vc.delegate = self
        vc.projectInfo = projectInfo
        self.window?.contentViewController?.presentAsModalWindow(vc)
    }
    
    func onItemClick(projectInfo: NXProject) {
        collectionDelegate?.beforeSelectItem(projectInfo: projectInfo)
        selectProjectItem(info: projectInfo)
    }
}

//MARK: NXCreateByOtherDelegate
extension NXHomeProjectView: NXCreateByOtherDelegate{
    func onBkBtnClick(projectInfo: NXProject){
        collectionDelegate?.beforeSelectItem(projectInfo: projectInfo)
        selectProjectItem(info: projectInfo)
    }
}

//MARK: NXCreateNewProjectDelegate
extension NXHomeProjectView: NXCreateNewProjectDelegate{
    func onCreateProjectCreate() {
        newProjectVC = NXNewProjectVC()
        newProjectVC?.delegate = self
        
        self.window?.contentViewController?.presentAsModalWindow(newProjectVC!)
    }
}

//MARK: NXNewProjectDelegate
extension NXHomeProjectView: NXNewProjectDelegate {
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String) {
        newProjectVC?.onCreateFinish()
        collectionDelegate?.onNewProject(title: title, description: description, emailArray: emailArray, invitationMsg: invitationMsg)
    }
}
extension NXHomeProjectView: NXProjectInviteDelegate{
    func onInvite(projectId: String, emailArray: [String], invitationMsg: String) {
        collectionDelegate?.onInvite(projectId: projectId, emailArray: emailArray, invitationMsg: invitationMsg)
    }
}
