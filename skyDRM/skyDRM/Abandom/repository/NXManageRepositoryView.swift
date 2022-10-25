//
//  NXManageRepositoryVC.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXManageRepositoryView: NXProgressIndicatorView, NSTextFieldDelegate {
    
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var updateBtn: NSButton!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var nameTipLabel: NSTextField!
    @IBOutlet weak var leftView: NSView!
    @IBOutlet weak var warningLabel: NSTextField!
    var disconnectView: NXDisconnectRepoView!
    weak var delegate: NXRepositoryActionDelegate?
    var currentRepoItem = NXRMCRepoItem()
    var allRepos = [NXRMCRepoItem]()
    var allReposNameArray = NSMutableArray()
    
    override func removeFromSuperview() {
        if disconnectView != nil{
            disconnectView.removeFromSuperview()
            disconnectView = nil
        }
        super.removeFromSuperview()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.backgroundColor = BK_COLOR
        guard let frame = self.window?.frame else {
            return
        }
        self.window?.setFrame(NSMakeRect(frame.minX, frame.minY, 550, 600), display: true)
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        nameLabel.wantsLayer = true
        nameLabel.layer?.borderWidth = 2.5
        nameLabel.layer?.borderColor = NSColor.black.cgColor
        nameLabel.placeholderString = NSLocalizedString("REPOSITORY_ADD_EMPTY_DISPLAY_NAME", comment: "")
        nameLabel.delegate = self

        nameTipLabel.stringValue = NSLocalizedString("REPOSITORY_DISPLAY_NAME", comment: "")
        warningLabel.textColor = NSColor.red
        warningLabel.isHidden = true
        updateBtn.wantsLayer = true
        updateBtn.layer?.backgroundColor = NSColor.white.cgColor
        updateBtn.layer?.cornerRadius = 5
        updateBtn.layer?.masksToBounds = true
        updateBtn.layer?.shadowColor = NSColor.black.cgColor
        updateBtn.layer?.shadowOpacity = 0.1
        updateBtn.layer?.borderWidth = 0.3
        updateBtn.layer?.borderColor = NSColor.black.cgColor
        updateBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        updateBtn.title = NSLocalizedString("REPOSITORY_UPDATE", comment: "")
        updateBtn.keyEquivalent = "\r"
        updateBtn.isEnabled = false
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.masksToBounds = true
        cancelBtn.layer?.shadowColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOpacity = 0.1
        cancelBtn.layer?.borderWidth = 0.3
        cancelBtn.layer?.borderColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        cancelBtn.title = NSLocalizedString("REPOSITORY_CANCEL", comment: "")
        disconnectView = (NXCommonUtils.createViewFromXib(xibName: "NXDisconnectRepoView", identifier: "disconnectRepoView", frame: nil, superView: leftView) as! NXDisconnectRepoView)
        disconnectView.delegate = self
        
    }
   func controlTextDidChange(_ obj: Notification) {
        if let label = obj.object as? NSTextField {
            if label == self.nameLabel {
                let newName = nameLabel.stringValue
                if newName == ""  {
                    NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: NSLocalizedString("REPOSITORY_ADD_EMPTY_DISPLAY_NAME", comment: ""))
                    updateBtn.isEnabled = false
                }
                else if allReposNameArray.contains(newName){
                    NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: String(format: NSLocalizedString("REPOSITORY_ADD_SAME_DISPLAY_NAME", comment: ""), nameLabel.stringValue))
                    updateBtn.isEnabled = false
                }
                else if false == checkName(name: newName) {
                    NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_INCORRECT_FORMAT", comment: ""))
                    updateBtn.isEnabled = false
                }
                else {
                    warningLabel.stringValue = ""
                    updateBtn.isEnabled = true
                }
            }
        }
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
    @IBAction func onCancel(_ sender: Any) {
        delegate?.closeManageView()
    }
    @IBAction func onUpdate(_ sender: Any) {
        warningLabel.stringValue = ""
        warningLabel.isHidden = true
        if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            
            let repoSerive = NXRepositoryService(userID: userId, ticket: ticket)
            repoSerive.delegate = self
            let tmpRepoItem = currentRepoItem.copy() as! NXRMCRepoItem
            tmpRepoItem.name = nameLabel.stringValue
            startAnimation()
            repoSerive.updateRepository(repo: tmpRepoItem)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "\u{1b}" {
            delegate?.gobackFromManageView()
        }
        else if event.characters == "\r" {
            onUpdate(self)
        }
        else {
            super.keyDown(with: event)
        }
    }
    func setRepoItem(repo: NXRMCRepoItem,allRepo:[NXRMCRepoItem]) {
        currentRepoItem = repo
        allRepos = allRepo
        var image: NSImage!
        let cloudName = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: currentRepoItem.type.rawValue)
        image = NSImage(named: cloudName)
        disconnectView.setInfo(image: image!, alias: repo.name, account: repo.accountName, type: repo.type.description)
        nameLabel.stringValue = repo.name
        
        for item in allRepos {
            allReposNameArray.add(item.name)
        }
        allReposNameArray.add("MyDrive")
        allReposNameArray.add("MyVault")
        allReposNameArray.add(NSLocalizedString("REPO_STRING_ALLFILES", comment: ""))
        allReposNameArray.add(NSLocalizedString("REPO_STRING_DELETEDFILES", comment: ""))
        allReposNameArray.add(NSLocalizedString("REPO_STRING_SHAREDFILES", comment: ""))
    }
}



extension NXManageRepositoryView: NXDisconnectRepoViewDelegate {
    func onDisconnect() {
        if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            
            let repoSerive = NXRepositoryService(userID: userId, ticket: ticket)
            repoSerive.delegate = self
            startAnimation()
            repoSerive.removeRepository(repo: currentRepoItem)
        }
    }
    func onGoback() {
        delegate?.gobackFromManageView()
    }
}

extension NXManageRepositoryView: NXRepositoryServiceDelegate {
    func removeRepositoryFinished(error: Error?) {
        if let _ = error {
            if let productName = Bundle.main.infoDictionary?["CFBundleName"] as! String? {
                NXCommonUtils.showNotification(title: productName, content: NSLocalizedString("REPOSITORY_DISCONNECT_ERROR", comment: ""))
                stopAnimation()
            }
        }
        else {
            DispatchQueue.main.async {
                //remove from core data
                if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
                    _ = CacheMgr.shared.deleteBoundService(userId: profile.userId, repository: self.currentRepoItem)
                    NXLoginUser.sharedInstance.removeRepository(repository: self.currentRepoItem)
                }
                //remove from drive SDK
                NXAuthMgr.shared.remove(item: self.currentRepoItem)
                //MARK:TODO - delete all the cache files of the repository
                self.stopAnimation()
                self.delegate?.disconnect()
            }
            
        }
    }
    func updateRepositoryFinished(error: Error?) {
        if error != nil {
            nameLabel.stringValue = currentRepoItem.name
            updateBtn.isEnabled = false
            if let backendError = error as? BackendError {
                switch backendError {
                case .notFound:
                    NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_NOT_FOUND", comment: ""))

                default:
                    NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_FAILED", comment: ""))
                }
            } else {
                NXCommonUtils.showWarningLabelNoFittingSize(label: warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_FAILED", comment: ""))
            }

            stopAnimation()
        }
        else {
            currentRepoItem.name = nameLabel.stringValue
            disconnectView.setAlias(alias: currentRepoItem.name)
            
            DispatchQueue.main.async {
                if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
                    _ = CacheMgr.shared.updateBoundService(userId: profile.userId, repository: self.currentRepoItem)
                }
                NXLoginUser.sharedInstance.updateRepository(repository: self.currentRepoItem)
                self.stopAnimation()
                self.delegate?.update()
                NXCommonUtils.showNotifyingLabel(label: self.warningLabel, str: NSLocalizedString("REPOSITORY_DISPLAY_NAME_SUCCEEDED", comment: ""))
            }
        }
    }
}
