//
//  NXManageProfileView.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXManageProfileView: NXProgressIndicatorView, NXUserServiceDelegate, NSTextFieldDelegate {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var displayNameLabel: NSTextField!
    @IBOutlet weak var emailLabel: NSTextField!
    @IBOutlet weak var phoneNumberLabel: NSTextField!
    @IBOutlet weak var updateBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var displayNameTip: NSTextField!
    @IBOutlet weak var emailTip: NSTextField!
    @IBOutlet weak var phoneNumberTip: NSTextField!
    @IBOutlet weak var warningLabel: NSTextField!
    weak var delegate: NXAccountActionDelegate?
    
    override func viewDidMoveToSuperview() {
        
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        //ui
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        self.window?.backgroundColor = NSColor.white
        displayNameLabel.wantsLayer = true
        displayNameLabel.layer?.borderWidth = 2.5
        displayNameLabel.layer?.borderColor = NSColor.black.cgColor
        displayNameLabel.placeholderString = NSLocalizedString("ACCOUNT_EMPTY_DISPLAY_NAME", comment: "")
        displayNameLabel.delegate = self
        displayNameTip.stringValue = NSLocalizedString("ACCOUNT_DISPLAY_NAME", comment: "")
        emailLabel.wantsLayer = true
        emailLabel.layer?.borderWidth = 2.5
        emailLabel.layer?.borderColor = NSColor.black.cgColor
        emailLabel.isEditable = false
        emailTip.stringValue = NSLocalizedString("ACCOUNT_EMAIL_ADDRESS", comment: "")
        phoneNumberLabel.wantsLayer = true
        phoneNumberLabel.layer?.borderWidth = 2.5
        phoneNumberLabel.layer?.borderColor = NSColor.black.cgColor
        phoneNumberLabel.placeholderString = NSLocalizedString("ACCOUNT_PHONE_NUMBER_TIP", comment: "")
        phoneNumberLabel.isEditable = false
        phoneNumberTip.stringValue = NSLocalizedString("ACCOUNT_PHONE_NUMBER", comment: "")
        phoneNumberLabel.isHidden = true
        phoneNumberTip.isHidden = true
        
        updateBtn.wantsLayer = true
        updateBtn.layer?.backgroundColor = NSColor.white.cgColor
        updateBtn.layer?.cornerRadius = 5
        updateBtn.layer?.masksToBounds = true
        updateBtn.layer?.shadowColor = NSColor.black.cgColor
        updateBtn.layer?.shadowOpacity = 0.1
        updateBtn.layer?.borderWidth = 0.3
        updateBtn.layer?.borderColor = NSColor.black.cgColor
        updateBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        updateBtn.title = NSLocalizedString("ACCOUNT_UPDATE", comment: "")
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
        cancelBtn.title = NSLocalizedString("ACCOUNT_CANCEL", comment: "")
        titleLabel.stringValue = NSLocalizedString("ACCOUNT_MANAGE_PROFILE", comment: "")
        warningLabel.textColor = NSColor.red
        warningLabel.isHidden = true
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            displayNameLabel.stringValue = profile.userName
            emailLabel.stringValue = profile.email
        }
    }
    @IBAction func onCancel(_ sender: Any) {
        delegate?.accountCloseManageView()
    }
    @IBAction func onGoback(_ sender: Any) {
        delegate?.accountGobackFromManageView()
    }
    @IBAction func onUpdate(_ sender: Any) {
        if updateBtn.isEnabled == false {
            return
        }
        
        guard  let profile = NXLoginUser.sharedInstance.nxlClient?.profile,
            let userID = profile.userId,
            let ticket = profile.ticket else {
                return
        }

        startAnimation()
        let userService = NXUserService(userID: userID, ticket: ticket)
        userService.delegate = self
        userService.updateDisplayName(displayName: displayNameLabel.stringValue)
    }
    override func keyDown(with event: NSEvent) {
        if event.characters == "\u{1b}" {
            onGoback(self)
        }
        else if event.characters == "\r" {
            onUpdate(self)
        }
        else {
            super.keyDown(with: event)
        }
    }
    @IBAction func onEditEnd(_ sender: Any) {
        onUpdate(self)
    }
    
     func controlTextDidChange(_ obj: Notification) {
        guard  let profile = NXLoginUser.sharedInstance.nxlClient?.profile else {
                return
        }
        if displayNameLabel.stringValue == "" {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_EMPTY_DISPLAY_NAME", comment: ""))
            updateBtn.isEnabled = false
            return
        }
        else if displayNameLabel.stringValue == profile.userName {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: String(format: NSLocalizedString("ACCOUNT_SAME_DISPLAY_NAME", comment: ""), displayNameLabel.stringValue))
            updateBtn.isEnabled = false
            return
        }
        
        if displayNameLabel.stringValue.count > 40{
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_DISPLAYNAME_TOOLONG", comment: ""))
            updateBtn.isEnabled = false
            return
        }
        if isInvalidDisplayName(displayName: displayNameLabel.stringValue){
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_INVALID_DISPLAY_NAME", comment: ""))
            updateBtn.isEnabled = false
            return
        }
        
        updateBtn.isEnabled = true
        hideWarning()
    }
    
    //NXUserServiceDelegate
    func updateDisplayNameFinished(error: Error?) {
        if error == nil {
            if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
                //FIXME: will update profile in keychain
                profile.userName = displayNameLabel.stringValue
                NXLKeyChain.update("NXLKeychainKey", data: NXLoginUser.sharedInstance.nxlClient)
            }
            delegate?.accountChangeName()
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("ACCOUNT_SUCCEEDED_DISPLAY_NAME", comment: ""))
        }
        else {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("ACCOUNT_FAILED_DISPLAY_NAME", comment: ""))
        }
        stopAnimation()
        delegate?.accountGobackFromManageView()
    }
    private func hideWarning() {
        warningLabel.stringValue = ""
        warningLabel.isHidden = true
    }
    private func focusLabel(){
        displayNameLabel.selectText(self)
        displayNameLabel.currentEditor()?.selectedRange = NSMakeRange(displayNameLabel.stringValue.count, 0)
    }
    
    func isInvalidDisplayName(displayName: String) -> Bool{
                
        let pattern = "^((?![\\~\\!\\@\\#\\$\\%\\^\\&\\*\\(\\)\\_\\+\\=\\[\\]\\{\\}\\;\\:\\\"\\\\\\/\\<\\>\\?]).)+$";
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        
        if(!predicate.evaluate(with: displayName)){
            return true
        }else{
            return false
        }
        
    }

}
