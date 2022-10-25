//
//  NXChangePwdViewController.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 2017/2/17.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXChangePwdView: NXProgressIndicatorView, NXUserServiceDelegate, NSTextFieldDelegate {
    
    @IBOutlet weak var currentPwdTip: NSTextField!
    @IBOutlet weak var newPwdTip: NSTextField!
    @IBOutlet weak var comfirmPwdTip: NSTextField!
    @IBOutlet weak var updateBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var warningLabel: NSTextField!
    @IBOutlet weak var currentPwdLabel: NSSecureTextField!
    @IBOutlet weak var newPwdLabel: NSSecureTextField!
    @IBOutlet weak var confirmPwdLabel: NSSecureTextField!
    weak var delegate: NXAccountActionDelegate?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard superview != nil else {
            return
        }
        self.window?.backgroundColor = NSColor.white
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        self.window?.backgroundColor = NSColor.white
        currentPwdLabel.wantsLayer = true
        currentPwdLabel.layer?.borderWidth = 2.5
        currentPwdLabel.layer?.borderColor = NSColor.black.cgColor
        currentPwdTip.stringValue = NSLocalizedString("ACCOUNT_CURRENT_PASSWORD", comment: "")
        newPwdLabel.wantsLayer = true
        newPwdLabel.layer?.borderWidth = 2.5
        newPwdLabel.layer?.borderColor = NSColor.black.cgColor
        newPwdLabel.delegate = self
        newPwdTip.stringValue = NSLocalizedString("ACCOUNT_NEW_PASSWORD", comment: "")
        confirmPwdLabel.wantsLayer = true
        confirmPwdLabel.layer?.borderWidth = 2.5
        confirmPwdLabel.layer?.borderColor = NSColor.black.cgColor
        confirmPwdLabel.delegate = self
        comfirmPwdTip.stringValue = NSLocalizedString("ACCOUNT_CONFIRM_NEW_PASSWORD", comment: "")
        warningLabel.isHidden = true
        warningLabel.textColor = NSColor.red
        
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
        updateBtn.wantsLayer = true
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.masksToBounds = true
        cancelBtn.layer?.shadowColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOpacity = 0.1
        cancelBtn.layer?.borderWidth = 0.3
        cancelBtn.layer?.borderColor = NSColor.black.cgColor
        cancelBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
        cancelBtn.title = NSLocalizedString("ACCOUNT_CANCEL", comment: "")

    }
    @IBAction func onCancel(_ sender: Any) {
        delegate?.accountCloseChangeView()
    }
    @IBAction func onGoback(_ sender: Any) {
        delegate?.accountGobackFromChangeView()
    }
     func controlTextDidChange(_ obj: Notification) {
        if let label = obj.object as? NSTextField {
            if label == self.newPwdLabel {
                if false == checkPassword(pwd: newPwdLabel.stringValue) {
                    NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_INCORRECT_NEW_PASSWORD", comment: ""))
                }
                else {
                    warningLabel.stringValue = ""
                }
            }
            else if label == self.confirmPwdLabel {
                if newPwdLabel.stringValue != confirmPwdLabel.stringValue {
                    NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_MISMATCH_NEW_PASSWORD", comment: ""))
                }
                else {
                    warningLabel.stringValue = ""
                }
            }
        }
    }
    override func keyDown(with event: NSEvent) {
        if event.characters == "\u{1b}" {
            onGoback(self)
        }
        else if event.characters == "\r" {
            onChangePassword(self)
        }
        else {
            super.keyDown(with: event)
        }
    }
    @IBAction func onChangePassword(_ sender: Any) {
        if currentPwdLabel.stringValue == "" {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_EMPTY_OLD_PASSWORD", comment: ""))
            self.window?.makeFirstResponder(currentPwdLabel)
            return
        }
        if newPwdLabel.stringValue == "" {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_EMPTY_NEW_PASSWORD", comment: ""))
            self.window?.makeFirstResponder(newPwdLabel)
            return
        }
        if newPwdLabel.stringValue != confirmPwdLabel.stringValue {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_MISMATCH_NEW_PASSWORD", comment: ""))
            confirmPwdLabel.stringValue = ""
            self.window?.makeFirstResponder(confirmPwdLabel)
            return
        }
        if false == checkPassword(pwd: newPwdLabel.stringValue) {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_INCORRECT_NEW_PASSWORD", comment: ""))
            confirmPwdLabel.stringValue = ""
            newPwdLabel.stringValue = ""
            self.window?.makeFirstResponder(newPwdLabel)
            return
        }
        if currentPwdLabel.stringValue == newPwdLabel.stringValue {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_SAME_NEW_PASSWORD", comment: ""))
            confirmPwdLabel.stringValue = ""
            newPwdLabel.stringValue = ""
            self.window?.makeFirstResponder(newPwdLabel)
            return
        }
        warningLabel.stringValue = ""
        warningLabel.isHidden = true
        if let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket,
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            
            let userService = NXUserService(userID: userId, ticket: ticket)
            userService.delegate = self
            startAnimation()
            userService.changePassword(old: currentPwdLabel.stringValue, new: newPwdLabel.stringValue)
        }
    }
    
    func changePasswordFinished(error: Error?) {
        stopAnimation()
        if error == nil {
            if delegate != nil {
                NSAlert.showAlert(withMessage: NSLocalizedString("MODIFY_PASSWORD_SUCCESS_TIPS", comment: ""), informativeText: "", dismissClosure: { (type) in
                    if type == .sure {
                        self.delegate?.accountLogout()
                    }
                })
            }
        }
        else {
            if let nsError = error as NSError? {
                if nsError.code == 1 {
                    NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_CURRENTPASSWORD_WRONG", comment: ""))
                } else {
                    NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_FAILED", comment: ""))
                }
            } else {
                NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("ACCOUNT_CHANGE_PASSWORD_FAILED", comment: ""))
            }
        }
    }
    
    private func checkPassword(pwd: String) -> Bool {
        if pwd.count < 8 {
            return false
        }
        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
        if pwd.rangeOfCharacter(from: characterset.inverted) == nil {
            return false
        }
        let numberset = CharacterSet(charactersIn: "0123456789")
        if pwd.rangeOfCharacter(from: numberset) == nil {
            return false
        }
        let alphaset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        if pwd.rangeOfCharacter(from: alphaset) == nil {
            return false
        }
        return true
    }
    private func hideWarning() {
        warningLabel.stringValue = ""
        warningLabel.isHidden = true
    }
}
