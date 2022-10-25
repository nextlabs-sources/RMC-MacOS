//
//  NXHomeTopView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/27.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeTopViewDelegate: NSObjectProtocol {
    func viewMyDrive()
    func viewMyVault()
    func viewAllFiles()
    func viewRepository(alias: String)
    func viewAccount()
}

class NXHomeTopView: NXFrameChangeView {

    @IBOutlet weak var gotoBtn: NXMouseEventButton!
    @IBOutlet weak var gotoImageButton: NSButton!
    @IBOutlet weak var welcomeLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var topView: NSView!
    @IBOutlet weak var greenLeftView: NSView!
    @IBOutlet weak var greenMidView: NSView!
    @IBOutlet weak var greenRightView: NSView!
    @IBOutlet weak var collectionHeaderLabel: NSTextField!
    @IBOutlet weak var avatarBtn: NSButton!
    @IBOutlet weak var avatarCircle: NXCircleText!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var collectionView: NXHomeCollectionView!
    @IBOutlet weak var noRepositoriesLabel: NSTextField!
    
    fileprivate var myspaceIndicatorView: NXMySpaceIndicatorView?
    fileprivate var protectfileView: NXGreenFeatureView?
    fileprivate var sharefileView: NXGreenFeatureView?
    fileprivate var addRepoView: NXGreenFeatureView?
    fileprivate var waitingView = NXProgressIndicatorView()
//    private var collectionView = NXHomeCollectionView()
    
    weak var delegate: NXHomeTopViewDelegate?
    
    private var myspaceStorageContext = 0
    fileprivate var currentRepoItem = NXRMCRepoItem()
    private var reposContext = 0
    
    private let viewHeightBase:CGFloat = 460.0
    //MARK: override
    override func removeFromSuperview() {
        super.removeFromSuperview()
        myspaceIndicatorView?.removeFromSuperview()
        protectfileView?.removeFromSuperview()
        sharefileView?.removeFromSuperview()
        addRepoView?.removeFromSuperview()
        waitingView.removeFromSuperview()
        NXLoginUser.sharedInstance.removeObserver(self, forKeyPath: "myDriveStorage", context: &self.myspaceStorageContext)
        NXLoginUser.sharedInstance.removeObserver(self, forKeyPath: "repositoryArray", context: &reposContext)
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            
            wantsLayer = true
            layer?.borderColor = NSColor.black.cgColor
            layer?.borderWidth = 0.3
            
            avatarBtn.imageScaling = .scaleAxesIndependently
            avatarBtn.layer?.cornerRadius = avatarBtn.frame.width/2
            avatarCircle.delegate = self
            
            myspaceIndicatorView = NXCommonUtils.createViewFromXib(xibName: "NXMySpaceIndicatorView", identifier: "mySpaceIndicatorView", frame: nil, superView: topView) as? NXMySpaceIndicatorView
            myspaceIndicatorView?.delegate = self
            let storage = NXLoginUser.sharedInstance.myDriveStorage
            myspaceIndicatorView?.drawProgress(used: storage.used, myVault: storage.myvault, total: storage.total)
            NXLoginUser.sharedInstance.addObserver(self, forKeyPath: "myDriveStorage", options: .new, context: &myspaceStorageContext)
            NXLoginUser.sharedInstance.addObserver(self, forKeyPath: "repositoryArray", options: .new, context: &reposContext)
            
            protectfileView = NXCommonUtils.createViewFromXib(xibName: "NXGreenFeatureView", identifier: "greenFeatureView", frame: nil, superView: greenLeftView) as? NXGreenFeatureView
            protectfileView?.name = NSLocalizedString("HOME_TOPVIEW_PROTECTFILEVIEW_NAME", comment: "")
            protectfileView?.image = NSImage(named:  "Protect FIle")
            protectfileView?.mouseDelegate = self
            sharefileView = NXCommonUtils.createViewFromXib(xibName: "NXGreenFeatureView", identifier: "greenFeatureView", frame: nil, superView: greenMidView) as? NXGreenFeatureView
            sharefileView?.name = NSLocalizedString("HOME_TOPVIEW_SHAREFILEVIEW_NAME", comment: "")
            sharefileView?.image = NSImage(named:  "Share File")
            sharefileView?.mouseDelegate = self
            addRepoView = NXCommonUtils.createViewFromXib(xibName: "NXGreenFeatureView", identifier: "greenFeatureView", frame: nil, superView: greenRightView) as? NXGreenFeatureView
            addRepoView?.name = NSLocalizedString("HOME_TOPVIEW_ADDREPROVIEW_NAME", comment: "")
            addRepoView?.image = NSImage(named:  "Connect")
            addRepoView?.mouseDelegate = self
            
            noRepositoriesLabel.stringValue = NSLocalizedString("HOME_TOPVIEW_NO_REPOSITORIES_TIP", comment: "")
            addSubview(waitingView)
            waitingView.frame = bounds
            waitingView.piDelegate = self
            collectionView.scrollDelegate = self
            collectionView.collectionDelegate = self
            scrollView.isHidden = true
            collectionHeaderLabel.stringValue = NSLocalizedString("HOME_TOPVIEW_CONNECTED_REPOSITORIES", comment: "")
            
            gotoBtn.title = NSLocalizedString("HOME_TOPVIEW_GOTO_MYSPACE", comment: "")
            
            welcomeLabel.stringValue = NSLocalizedString("HOME_TOPVIEW_WELCOME", comment: "")
            
            self.window?.makeFirstResponder(nil)
            
            guard let client = NXLoginUser.sharedInstance.nxlClient,
                let profile = client.profile,
                let name = profile.userName else {
                    return
            }
            nameLabel.stringValue = name
            nameLabel.sizeToFit()
            avatarCircle.isHidden = true
            if let iamge = NSImage(base64String: profile.avatar) {
                avatarBtn.image = iamge
                avatarCircle.isHidden = true
            }
            else {
                if let displayName = profile.displayName ?? profile.userName {
                    avatarCircle.text = NXCommonUtils.abbreviation(forUserName: displayName)
                    avatarCircle.extInfo = profile.email
                    let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
                    let index = displayName.index(displayName.startIndex, offsetBy: 1)
                    let firstStr = String(abbrevStr[..<index]).lowercased()
                    if let colorHexValue = NXCommonUtils.circleViewBKColor[firstStr]{
                        avatarCircle.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
                    }
                }
                avatarBtn.isHidden = true
            }
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myspaceStorageContext {
            let storage = NXLoginUser.sharedInstance.myDriveStorage
            myspaceIndicatorView?.drawProgress(used: storage.used, myVault: storage.myvault, total: storage.total)
        }
        else if context == &reposContext {
            refreshRepositoriesList()
        }
        else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    @IBAction func onGotoBtn(_ sender: Any) {
        delegate?.viewMyVault()
    }
    @IBAction func onGotoImage(_ sender: Any) {
        delegate?.viewAllFiles()
    }
    @IBAction func onAvatarBtnClick(_ sender: Any) {
        delegate?.viewAccount()
    }
    
    //MARK: public
    func refreshProfile(){
        DispatchQueue.main.async {
            guard let client = NXLoginUser.sharedInstance.nxlClient,
                let profile = client.profile,
                let name = profile.userName else {
                    return
            }
            self.nameLabel.stringValue = name
            if let iamge = NSImage(base64String: profile.avatar) {
                self.avatarBtn.image = iamge
                self.avatarCircle.isHidden = true
                self.avatarBtn.isHidden = false
            }
            else {
                if let displayName = profile.displayName ?? profile.userName {
                    self.avatarCircle.text = NXCommonUtils.abbreviation(forUserName: displayName)
                    self.avatarCircle.extInfo = profile.email
                    let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
                    let index = displayName.index(displayName.startIndex, offsetBy: 1)
                    let firstStr = String(abbrevStr[..<index]).lowercased()
                    if let colorHexValue = NXCommonUtils.circleViewBKColor[firstStr]{
                        self.avatarCircle.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
                    }
                }
                self.avatarBtn.isHidden = true
                self.avatarCircle.isHidden = false
            }
        }
    }
    func refreshRepositoriesList() {
        if NXLoginUser.sharedInstance.repository().count == 0 {
            noRepositoriesLabel.isHidden = false
            scrollView.isHidden = true
        }
        else {
            insertCollector()
            scrollView.isHidden = false
            noRepositoriesLabel.isHidden = true
        }
    }
    func updateUIFromNetwork() {
        if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            
            NXLoginUser.sharedInstance.updateMySpaceStorage()
            
            let repoSerive = NXRepositoryService(userID: userId, ticket: ticket)
            repoSerive.delegate = self
            repoSerive.getRepositories()
            
            let userService = NXUserService(userID: userId, ticket: ticket)
            userService.delegate = self
            userService.getProfile()
        }
        
    }
    //MARK: private
    fileprivate func insertCollector() {
        let count = NXLoginUser.sharedInstance.repository().count
        let row: Int = (count+2)/3
        if row > 0 {
            let itemHeight  = NXHomeCollectionView.UIConstant.itemHeight
            let rowGap = NXHomeCollectionView.UIConstant.rowGap
            let rowHeight: CGFloat = CGFloat(row)*CGFloat(itemHeight)
            let gapHeight: CGFloat = CGFloat(row-1)*CGFloat(rowGap)
            let height: CGFloat = rowHeight+gapHeight
            let topViewFrame = topView.frame
            let protectViewFrame = greenLeftView.frame
            collectionView.repoItems = NXLoginUser.sharedInstance.repository()
            self.frame.size.height = viewHeightBase + height
            waitingView.frame = bounds
            scrollView.frame = NSMakeRect(topViewFrame.minX, protectViewFrame.maxY+40, topViewFrame.width, height)
            scrollView.isHidden = false
            collectionView.frame = NSMakeRect(0, 0, topViewFrame.width, height)
            frameDelegate?.onFrameChange(frame: frame)
        }
    }
}
extension NXHomeTopView: NXUserServiceDelegate {
    func getProfileFinished(name: String?, email: String?, avatar: String?, error: Error?) {
        if error == nil {
            if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
                profile.userName = name
                profile.email = email
                profile.avatar = avatar
                
                if let client = NXLoginUser.sharedInstance.nxlClient {
                    // save client in keychain
                    NXLKeyChain.update("NXLKeychainKey", data: client)
                    self.refreshProfile()
                }
            }
        }
    }
}
extension NXHomeTopView: NXRepositoryServiceDelegate {
    func getRepositoriesFinished(repositories: Array<Any>?, error: Error?) {
        DispatchQueue.main.async {
            if error == nil,
                repositories != nil{
                
                guard let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
                    let repositoryArray = repositories as? [NXRMCRepoItem] else {
                        return
                }
                
                // sync core data with RMS
                let delRepository: (NXBoundService) -> Void = { boundService in
                    guard let type = ServiceType(rawValue: boundService.serviceType) else {
                        return
                    }
                    let repo = NXRMCRepoItem()
                    repo.type = type
                    repo.token = boundService.serviceAccountToken
                    repo.accountId = boundService.serviceAccountId
                    NXAuthMgr.shared.remove(item: repo)
                }
                _ = CacheMgr.shared.saveBoundService(userId: userId, repositories: repositoryArray, beforeDelBoundService: delRepository )
                // differentiate core data with RMS
                let showingType: [ServiceType] = [.kServiceDropbox, .kServiceGoogleDrive, .kServiceOneDrive, .kServiceSharepointOnline]
                let showRepositories = repositoryArray.filter{showingType.contains($0.type)}
                let boundRootArray = CacheMgr.shared.getAllBoundService(userId: userId)
                for repo in showRepositories {
                    for item in boundRootArray {
                        if item.boundService.repoId == repo.repoId,
                            item.boundService.serviceType == repo.type.rawValue,
                            item.boundService.serviceAccount == repo.accountName {
                            repo.isAuth = item.boundService.serviceIsAuthed
                            break
                        }
                    }
                }
                // refresh UI
                NXLoginUser.sharedInstance.repository(repositories: showRepositories)
                DispatchQueue.main.async {
                    self.refreshRepositoriesList()
                }
            }
        }
    }
    
    func updateRepositoryFinished(error: Error?) {
        
        guard let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId else {
            return
        }
        
        if let error = error as? BackendError
        {
            // 404: not exist
            switch error {
            case .notFound:
                NSAlert.showAlert(withMessage: NSLocalizedString("HOME_REPOSITORY_NOT_EXIST", comment: ""))
                NXAuthMgr.shared.remove(item: self.currentRepoItem)
                NXLoginUser.sharedInstance.removeRepository(repository: self.currentRepoItem)
                
                DispatchQueue.main.async {
                    self.refreshRepositoriesList()
                }
                return
            default:
                break
            }
           
        }
        
        DispatchQueue.main.async {
            if (CacheMgr.shared.addAndUpdateBoundService(userId: userId, repository: self.currentRepoItem)) {
                NXLoginUser.sharedInstance.updateRepository(repository: self.currentRepoItem)
            }
            self.refreshRepositoriesList()
        }
    }
}

extension NXHomeTopView: NXScrollWheelCollectionViewDelegate {
    func onScrollWheel(event: NSEvent) {
        scrollWheel(with: event)
    }
}

extension NXHomeTopView: NXAuthMgrDelegate {
    func addFinished(repo: NXRMCRepoItem?, error: NSError?) {
        defer {
            waitingView.stopAnimation()
        }
        if let _ = error {
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("REPOSITORY_ADD_FAILED", comment: ""))
            }
            return
        }
        if let repo = repo {
            if self.currentRepoItem != repo {
                NSAlert.showAlert(withMessage: NSLocalizedString("HOME_REPOSITORY_REAUTH_FAILED", comment: ""))
                NXAuthMgr.shared.remove(item: repo)
                return
            }
            
            // check repository is exist, no need to update token
            let webToken = self.currentRepoItem.token
            self.currentRepoItem.token = repo.token
            repo.token = webToken

            self.currentRepoItem.accountId = repo.accountId
            self.currentRepoItem.isAuth = true
            
            if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
                let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
                
                let repoSerive = NXRepositoryService(userID: userId, ticket: ticket)
                repoSerive.delegate = self
                
                repoSerive.updateRepository(repo: repo)
            }
            
        }
    }
}
extension NXHomeTopView: NXMySpaceIndicatorViewDelegate {
    func viewMyDrive() {
        delegate?.viewMyDrive()
    }
    func viewMyVault() {
        delegate?.viewMyVault()
    }
}

extension NXHomeTopView: NXHomeCollectionViewDelegate {
    func onAuth(id: Int) {
        let repos = NXLoginUser.sharedInstance.repository()
        guard repos.count > id,
            id >= 0 else {
                return
        }
        currentRepoItem = repos[id]
        
        if currentRepoItem.type == .kServiceOneDrive,
            NXCommonUtils.loadOnedriveState() {
            NSAlert.showAlert(withMessage: String(format: NSLocalizedString("REPOSITORY_ADD_ALERT_OTHER_ACCOUNT", comment: ""), "OneDrive"))
            return
        }
        guard let window = self.window else {
            return
        }
        NXAuthMgr.shared.add(item: currentRepoItem, window: window)
        NXAuthMgr.shared.delegate = self
        waitingView.setClose(isClosable: NXAuthMgr.shared.supportCancel())
        waitingView.startAnimation()
    }
    func onMouseDown(id: Int) {
        let repos = NXLoginUser.sharedInstance.repository()
        guard repos.count > id,
            id >= 0 else {
            return
        }
        if repos[id].isAuth == true {
            delegate?.viewRepository(alias: repos[id].name)
        }
        else {
            NSAlert.showAlert(withMessage: NSLocalizedString("HOME_REPOSITORY_TIP", comment: ""))
        }
    }
}

extension NXHomeTopView: NXGreenFeatureViewDelegate {
    func mouseDownView(sender: Any, event: NSEvent) {
        if sender as? NXGreenFeatureView == addRepoView {
            let repoVC = NXRepositoryViewController()
            repoVC.mainView = .add
            NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(repoVC)
        }
        else if sender as? NXGreenFeatureView == protectfileView {
            let protectVC = NXHomeProtectVC()
            NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(protectVC)
        }
        else if sender as? NXGreenFeatureView == sharefileView {
            let shareVC = NXHomeShareVC()
            NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(shareVC)
        }
    }
}

extension NXHomeTopView: MouseEventDelegate {
    func mouseEvent(exited event: NSEvent) {
        
    }
    func mouseEvent(entered event: NSEvent) {
        
    }
    func mouseEvent(down: NSEvent) {
        delegate?.viewAccount()
    }
}

extension NXHomeTopView: NXProgressIndicatorDelegate {
    func onPICancel() {
        NXAuthMgr.shared.cancel()
    }
}
