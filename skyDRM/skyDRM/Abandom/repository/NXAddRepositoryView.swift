//
//  NXAddRepositoryVC.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXAddRepositoryView: NXProgressIndicatorView {
    
    @IBOutlet weak var gobackBtn: NSButton!
    @IBOutlet weak var addRepoLabel: NSTextField!
    @IBOutlet weak var serviceLabel: NSTextField!
    @IBOutlet weak var popupBtn: NSPopUpButton!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var nameTipLabel: NSTextField!
    @IBOutlet weak var connectTipLabel: NSTextField!
    @IBOutlet weak var connectBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var warningLabel: NSTextField!
    weak var delegate: NXRepositoryActionDelegate?
    fileprivate var currentRepoItem = NXRMCRepoItem()
    private let existingRepositories: [ServiceType] = [.kServiceDropbox, .kServiceOneDrive, .kServiceGoogleDrive]
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        popupBtn.addItem(withTitle: "")
        _ = existingRepositories.map({popupBtn.addItem(withTitle: $0.description)})
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.backgroundColor = NSColor.white
        guard let frame = self.window?.frame else {
            return
        }
        self.window?.setFrame(NSMakeRect(frame.minX, frame.minY, 550, 600), display: true)
        
        adjustWindowPosition(with: NXCommonUtils.getMainWindow())
    }
    
    private func adjustWindowPosition(with parentWindow: NSWindow?) {
        guard
            let currentWindow = self.window,
            let parentWindow = parentWindow
            else { return }
        
        let x = (parentWindow.frame.width - currentWindow.frame.width)/2
        let y = (parentWindow.frame.height - currentWindow.frame.height)/2
        currentWindow.setFrameOrigin(CGPoint(x: parentWindow.frame.origin.x + x, y: parentWindow.frame.origin.y + y))
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        nameLabel.placeholderString = NSLocalizedString("REPOSITORY_DISPLAY_ANME_TIP", comment: "")
        connectBtn.wantsLayer = true
        connectBtn.layer?.backgroundColor = NSColor.white.cgColor
        connectBtn.layer?.cornerRadius = 5
        connectBtn.layer?.masksToBounds = true
        connectBtn.layer?.shadowColor = NSColor.black.cgColor
        connectBtn.layer?.shadowOpacity = 0.1
        connectBtn.layer?.borderWidth = 0.3
        connectBtn.layer?.borderColor = NSColor.black.cgColor
        connectBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        connectBtn.keyEquivalent = "\r"
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.masksToBounds = true
        cancelBtn.layer?.shadowColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOpacity = 0.1
        cancelBtn.layer?.borderWidth = 0.3
        cancelBtn.layer?.borderColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        nameLabel.wantsLayer = true
        nameLabel.layer?.borderWidth = 2.5
        nameLabel.layer?.borderColor = NSColor.black.cgColor
        
        gobackBtn.keyEquivalent = "\u{1b}"
        popupBtn.wantsLayer = true
        popupBtn.layer?.borderWidth = 2.5
        popupBtn.layer?.borderColor = NSColor.black.cgColor
        
        warningLabel.textColor = NSColor.red
        warningLabel.isHidden = true
        
        //insert an empty item in popup button
        addRepoLabel.stringValue = NSLocalizedString("REPOSITORY_ADD", comment: "")
        serviceLabel.stringValue = NSLocalizedString("REPOSITORY_SERVICE_PROVIDER", comment: "")
        nameTipLabel.stringValue = NSLocalizedString("REPOSITORY_DISPLAY_NAME", comment: "")
        connectTipLabel.stringValue = NSLocalizedString("REPOSITORY_CONNECT_TIP", comment: "")
        connectBtn.title = NSLocalizedString("REPOSITORY_CONNECT_BUTTON", comment: "")
        cancelBtn.title = NSLocalizedString("REPOSITORY_CANCEL", comment: "")
        setCancelButtonFrame(frame: cancelBtn.frame)
    }

    override func keyDown(with event: NSEvent) {
        if event.characters == "\u{1b}" {
            onGoBack(self)
        }
        else if event.characters == "\r" {
            onConnect(self)
        }
        else {
            super.keyDown(with: event)
        }
    }
    override func onCancelAnimation(_ sender: Any) {
        NXAuthMgr.shared.cancel()
    }
    @IBAction func onEditEnd(_ sender: Any) {
        onConnect(self)
    }
    @IBAction func onPopupSelected(_ sender: Any) {
        let index = popupBtn.indexOfSelectedItem - 1
        guard index < existingRepositories.count else {
            return
        }
        popupBtn.setTitle(existingRepositories[index].description)
    }
    @IBAction func onCancel(_ sender: Any) {
        delegate?.closeAddView()
    }
    @IBAction func onGoBack(_ sender: Any) {
        delegate?.gobackFromAddView()
    }
    @IBAction func onConnect(_ sender: Any) {
        guard checkUI() == true else {
            return
        }
        let index = popupBtn.indexOfSelectedItem - 1
        currentRepoItem.type = existingRepositories[index]
        currentRepoItem.name = nameLabel.stringValue
        
        guard let window = self.window else {
            return
        }
        NXAuthMgr.shared.add(item: currentRepoItem, window: window)
        NXAuthMgr.shared.delegate = self
        setClose(isClosable: NXAuthMgr.shared.supportCancel())
        startAnimation()
    }
    private func checkName(name: String) -> Bool {
        if name.count > 40 {
            return false
        }
        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789 -_")
        if name.rangeOfCharacter(from: characterset.inverted) != nil {
            return false
        }
        return true
    }
    private func checkUI() -> Bool {
        let index = popupBtn.indexOfSelectedItem - 1
        if index < 0 {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_EMPTY_SERVICE_PROVIDER", comment: ""))
            self.window?.makeFirstResponder(popupBtn)
            return false
        }
        if nameLabel.stringValue == "" {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_EMPTY_DISPLAY_NAME", comment: ""))
            focusLabel()
            return false
        }
        else if checkName(name: nameLabel.stringValue) == false {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_INCORRECT_FORMAT", comment: ""))
            focusLabel()
            return false
        }
        else {
            var filterNames = NXLoginUser.sharedInstance.repository().map{return $0.name}
            filterNames.append("MyDrive")
            filterNames.append("MyVault")
            filterNames.append(NSLocalizedString("REPO_STRING_ALLFILES", comment: ""))
            filterNames.append(NSLocalizedString("REPO_STRING_DELETEDFILES", comment: ""))
            filterNames.append(NSLocalizedString("REPO_STRING_SHAREDFILES", comment: ""))
            if filterNames.contains(nameLabel.stringValue){
                NXCommonUtils.showWarningLabel(label: warningLabel, str: String(format: NSLocalizedString("REPOSITORY_ADD_SAME_DISPLAY_NAME", comment: ""), nameLabel.stringValue))
                focusLabel()
                return false
            }
        }
        
        let limitRepositories: [ServiceType] = [.kServiceOneDrive]
        let repositories = NXLoginUser.sharedInstance.repository()
        if limitRepositories.contains(where: {$0 == existingRepositories[index]})  {
            if repositories.contains(where: {$0.type == existingRepositories[index]}) {
                NSAlert.showAlert(withMessage: NSLocalizedString("REPOSITORY_ADD_ALERT_SAME_ACCOUNT", comment: ""))
                
                return false
            }
            else {
                if NXCommonUtils.loadOnedriveState() {
                    NSAlert.showAlert(withMessage: String(format: NSLocalizedString("REPOSITORY_ADD_ALERT_OTHER_ACCOUNT", comment: ""), existingRepositories[index].description))
                    return false
                }
            }
            
        }

        warningLabel.stringValue = ""
        warningLabel.isHidden = true
        return true
    }
    
    private func focusLabel(){
        nameLabel.selectText(self)
        nameLabel.currentEditor()?.selectedRange = NSMakeRange(nameLabel.stringValue.count, 0)
    }
}

extension NXAddRepositoryView: NXRepositoryServiceDelegate
{
    func addRepositoryFinished(repoId: String?, error: Error?) {
        if let _ = error {
            NXAuthMgr.shared.remove(item: self.currentRepoItem)
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_FAILED", comment: ""))
            stopAnimation()
        }
        else if let repoId = repoId {
            currentRepoItem.repoId = repoId
            currentRepoItem.isAuth = true
            // save to core data
            let bs = NXBoundService()
            bs.serviceAccount = currentRepoItem.accountName
            bs.serviceAccountId = currentRepoItem.accountId
            bs.serviceAccountToken = currentRepoItem.token
            bs.serviceAlias = currentRepoItem.name
            bs.repoId = repoId
            
            bs.serviceIsAuthed = true
            bs.serviceIsSelected = false
            bs.serviceType = currentRepoItem.type.rawValue
            guard let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId else {
                return
            }
            bs.userId = userId
            
            DispatchQueue.main.async {
                if (CacheMgr.shared.addNewBoundService(bs: bs)) {
                    NXLoginUser.sharedInstance.addRepository(repository: self.currentRepoItem)
                    self.stopAnimation()
                    if self.currentRepoItem.type == .kServiceOneDrive {
                        NXCommonUtils.saveOnedriveState(bExisted: true)
                    }
                    NXCommonUtils.showWarningLabel(label: self.warningLabel, str: NSLocalizedString("REPOSITORY_ADD_SUCCEEDED", comment: ""))
                    self.delegate?.connect()
                }
            }
        }
    }
}

extension NXAddRepositoryView: NXAuthMgrDelegate {
    func addFinished(repo: NXRMCRepoItem?, error: NSError?) {
        if let _ = error {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_FAILED", comment: ""))
            stopAnimation()
        }
        else if let repo = repo {
            if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
                let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
                
                let repoSerive = NXRepositoryService(userID: userId, ticket: ticket)
                repoSerive.delegate = self
                
                currentRepoItem = repo.copy() as! NXRMCRepoItem
                if NXLoginUser.sharedInstance.repository().contains(where: {$0 == repo}) {
                    NXAuthMgr.shared.remove(item: repo)
                     NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_FAILED_EXISTING", comment: ""))
                    stopAnimation()
                    return
                }
                repoSerive.addRepository(repo: currentRepoItem)
            }
        }
    }
}
