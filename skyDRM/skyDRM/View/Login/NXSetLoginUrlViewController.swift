//
//  NXSetLoginUrlViewController.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 25/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXSetLoginUrlViewControllerDelegate: NSObjectProtocol {
    func willLoginFinished()
    func didLoginFinished()
}
extension NXSetLoginUrlViewControllerDelegate {
    func willLoginFinished(){}
    func didLoginFinished(){}
}

class NXSetLoginUrlViewController: NSViewController {

    @IBOutlet weak var promptLabel: NSTextField!
    @IBOutlet weak var avatarImageView: NSImageView!
    @IBOutlet weak var urlTitleLabel: NSTextField!
    @IBOutlet weak var inputUrlTextfield: NSTextField!
    @IBOutlet weak var inputUrlComboBox: NSComboBox!
    @IBOutlet weak var personalButton: NSButton!
    @IBOutlet weak var companyButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var rememberUrlSelectButton: NSButton!
    @IBOutlet weak var operationPromptLabel: NSTextField!
    
    weak var delegate: NXSetLoginUrlViewControllerDelegate?
    var isNoWelcomeViewFrom = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        
        operationPromptLabel.isHidden = false
        rememberUrlSelectButton.isHidden = false
        
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        urlTitleLabel.textColor = NSColor(colorWithHex: "#4F4F4F", alpha: 1.0)
        
        inputUrlTextfield.alignment = NSTextAlignment.left
        inputUrlTextfield.wantsLayer = true
        inputUrlTextfield.stringValue = UserDefaults.standard.string(forKey: "lastRouter")?.lowercased() ?? ""
        inputUrlTextfield.layer?.borderWidth = 2.0;
        inputUrlTextfield.layer?.borderColor =  NSColor(colorWithHex: "#D8D8D8", alpha: 1.0)?.cgColor
        inputUrlTextfield.isEditable = false
        inputUrlTextfield.isEnabled = false
        inputUrlTextfield.placeholderString = DEFAULT_PERSONAL_LOGIN_URL
        inputUrlTextfield.stringValue = DEFAULT_PERSONAL_LOGIN_URL
        
        inputUrlComboBox.alignment = NSTextAlignment.left
        inputUrlComboBox.removeAllItems()
        if let routers = NXCacheManager.loadRecentRouter(), routers.count > 0 {
            inputUrlComboBox.addItems(withObjectValues: routers)
            inputUrlComboBox.selectItem(at: 0)
        }
        
        inputUrlComboBox.isHidden = false
        inputUrlTextfield.isHidden = true
        
        location()
        
        
        companyButton.isHidden = true
        personalButton.isHidden = true
    }
    
    fileprivate func location() {
        promptLabel.stringValue = "LOGIN_YOUR_COUNT".localized
        personalButton.title = "LOGIN_PERSONAL_ACCOUNT".localized
        companyButton.title = "LOGIN_COMPANY_ACCOUNT".localized
        urlTitleLabel.stringValue = "LOGIN_URL".localized
        nextButton.title =  "SKYDRM_NEXT".localized
        rememberUrlSelectButton.title = "LOGIN_REMEMBER_URL".localized
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.styleMask = NSWindow.StyleMask([.closable,.titled,.miniaturizable])
        self.view.window?.title = NSLocalizedString("TITLE_SkyDRM_Desktop", comment: "")
        self.view.window?.delegate = self
    }
    
    deinit {

    }
    
    @IBAction func onTapNextButton(_ sender: Any) {
        
        let router: String = {
            if personalButton.state == .on {
                return inputUrlTextfield.stringValue
            } else {
                return inputUrlComboBox.stringValue
            }
        }()
        
        guard router.isEmpty == false else {
            NXCommonUtils.showWarningLabel(label: operationPromptLabel, str: NSLocalizedString("MSG_INPUT_URL_EMPTY", comment: ""))
            return
        }

//        if companyButton.state == .on, NXCommonUtils.checkIsDefaultRouter(url: router) {
//            NXCommonUtils.showWarningLabel(label: operationPromptLabel,str: NSLocalizedString("MSG_INPUT_URL_INVALID", comment: ""))
//            return
//        }
        
        if  NXCommonUtils.checkIsValidateUrl(urlString: router) {
            NXCommonUtils.showWarningLabel(label: operationPromptLabel, str: "")
            NXClient.getCurrentClient().initTenant(router: router, tenantID: "")
            let isPersonal = (personalButton.state == .on)
            NXClient.getCurrentClient().loginAsModalWindow(viewController: self, isPersonal: isPersonal, completion:{ (error) in
                guard error == nil else {
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .noNetwork) = sdmlError {
                        NXCommonUtils.showWarningLabel(label: self.operationPromptLabel, str:"ERROR_LOSE_CONNECT".localized)
                           return
                    }

                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .cannotGetLoginURL) = sdmlError {
                       NXCommonUtils.showWarningLabel(label: self.operationPromptLabel, str:"ERROR_LOGIN_GET_ROUTER_URL_FAILED".localized)
                           return
                    }
                    
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .requestTimeout) = sdmlError {
                        NXCommonUtils.showWarningLabel(label: self.operationPromptLabel, str:"ERROR_LOGIN_REQUEST_TIMEOUT".localized)
                           return
                    }
                    
                    NXCommonUtils.showWarningLabel(label: self.operationPromptLabel, str:"ERROR_LOGIN_WEBVIEW_LOAD_FAILED".localized)
                    
                    return
                  }
                
                let tenant = NXClient.getCurrentClient().getTenant().0!
                let user = NXClient.getCurrentClient().getUser().0!
                NXClientUser.shared.setLoginUser(tenant: tenant, user: user)
                
                if self.companyButton.state == NSControl.StateValue.on {
                    if self.rememberUrlSelectButton.state == NSControl.StateValue.on {
                        NXCacheManager.saveRecentRouter(router: router)
                    }
                }

                self.presentingViewController?.dismiss(self)
                
                self.delegate?.willLoginFinished()
                self.delegate?.didLoginFinished()
            }
            )
        }else{
            NXCommonUtils.showWarningLabel(label: operationPromptLabel,str: NSLocalizedString("MSG_INPUT_URL_INVALID", comment: ""))
            return
        }
    }
    
    @IBAction func onTapRememberURLButton(_ sender: Any) {
        
    }
    
    @IBAction func onTapPersonalOrCompanyButton(_ sender: Any) {
        switch (sender as! NSButton).tag {
        case 1: self.onTapPersonalButton(sender)
        case 2: self.onTapCompanyButton(sender)
        default : break
        }
    }
        
    func onTapPersonalButton(_ sender: Any){
        urlTitleLabel.stringValue = NSLocalizedString("TITLE_SETURL_PAGE_URL", comment: "")
        operationPromptLabel.isHidden = true
        
        rememberUrlSelectButton.isHidden = true
        
        inputUrlComboBox.isHidden = true
        inputUrlTextfield.isHidden = false
    }
        
    func onTapCompanyButton(_ sender: Any){
        urlTitleLabel.stringValue = NSLocalizedString("TITLE_SETURL_PAGE_ENTERURL", comment: "")
        operationPromptLabel.stringValue = NSLocalizedString("MSG_YOU_CAN_CHANGE_URL", comment: "")
        operationPromptLabel.textColor =  NSColor(colorWithHex: "#828282", alpha: 1.0)
        
        operationPromptLabel.isHidden = false
        rememberUrlSelectButton.isHidden = false
        
        inputUrlComboBox.isHidden = false
        inputUrlTextfield.isHidden = true
    }
}

//extension NXSetLoginUrlViewController {
//    fileprivate func setRestApiAddress() {
//        hostURLString = NXCommonUtils.getCurrentRMSAddress()
//    }
//    fileprivate func prepareAfterLogin() {
//        setRestApiAddress()
//    }
//}

//extension NXSetLoginUrlViewController :NXUserServiceDelegate {
//    func getServerLoginURLFinished(loginURL: String?,error: Error?)
//    {
//    }
//}

extension NXSetLoginUrlViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if isNoWelcomeViewFrom {
            NXWindowsManager.sharedInstance.setupTray()
        }
    }
}

