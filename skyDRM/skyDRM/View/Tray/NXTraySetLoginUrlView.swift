//
// NXTraySetLoginUrlView.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2018/8/7.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXTraySetLoginUrlViewDelegate: NSObjectProtocol {
    func onTapButton(companyStateOn:Bool?,userInputedURL:String!,cookies:String!,urlRequest:URLRequest!, isPersonal: Bool)
    func changePopoverAppearanceToVibrantLight(flag:Bool)
}

class NXTraySetLoginUrlView: NSView {
    
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
    
    var waitingView: NXWaitingView?
    var maskView: NSImageView?
    
     weak var delegate: NXTraySetLoginUrlViewDelegate?
    

    fileprivate func location() {
        promptLabel.stringValue = "LOGIN_YOUR_COUNT".localized
        personalButton.title = "LOGIN_PERSONAL_ACCOUNT".localized
        companyButton.title = "LOGIN_COMPANY_ACCOUNT".localized
        nextButton.title = "SKYDRM_NEXT".localized
        rememberUrlSelectButton.title = "LOGIN_REMEMBER_URL".localized
        
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: window)
        location()
        self.configureUI()
        
        companyButton.isHidden = true
        personalButton.isHidden = true
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
    }
    
    @IBAction func onTapNextButton(_ sender: Any) {
        self.delegate?.changePopoverAppearanceToVibrantLight(flag: false)
        
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
        
        self.showLoading()
        
        if  NXCommonUtils.checkIsValidateUrl(urlString: router) {
            NXCommonUtils.showWarningLabel(label: operationPromptLabel, str: "")
            NXClient.getCurrentClient().initTenant(router: router, tenantID: "")
            NXClient.getCurrentClient().getUserRouterUrl {[weak self] (cookies, urlRequest, error) in
                self?.hideLoading()
                self?.deallocWaitView()
            
                if let error = error{
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .noNetwork) = sdmlError {
                        NXCommonUtils.showWarningLabel(label: self?.operationPromptLabel ?? NSTextField(), str:"ERROR_LOSE_CONNECT".localized)
                        return
                    }
                    
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .cannotGetLoginURL) = sdmlError {
                        NXCommonUtils.showWarningLabel(label: self?.operationPromptLabel ?? NSTextField(), str:"ERROR_LOGIN_GET_ROUTER_URL_FAILED".localized)
                        return
                    }
                    
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.loginFailed(reason: .requestTimeout) = sdmlError {
                        NXCommonUtils.showWarningLabel(label:self?.operationPromptLabel ?? NSTextField(), str:"ERROR_LOGIN_REQUEST_TIMEOUT".localized)
                        return
                    }
                    
                    NXCommonUtils.showWarningLabel(label: self?.operationPromptLabel ?? NSTextField(), str:"ERROR_LOGIN_GET_ROUTER_URL_FAILED".localized)
                    return
                }
                
                
                let isPersonal = (self?.companyButton.state == .on) ? false : true
                if self?.companyButton.state == NSControl.StateValue.on {
                    if self?.rememberUrlSelectButton.state == NSControl.StateValue.on {
                        self?.delegate?.onTapButton(companyStateOn:true,userInputedURL: router, cookies: cookies!, urlRequest: urlRequest!, isPersonal: isPersonal)
                    } else {
                        self?.delegate?.onTapButton(companyStateOn:false,userInputedURL: router, cookies: cookies!, urlRequest: urlRequest!, isPersonal: isPersonal)
                    }
                } else {
                    self?.delegate?.onTapButton(companyStateOn:nil,userInputedURL: router, cookies: cookies!, urlRequest: urlRequest!, isPersonal: isPersonal)
                }
                
                return
            }
        } else {
            NXCommonUtils.showWarningLabel(label: operationPromptLabel,str: NSLocalizedString("MSG_INPUT_URL_INVALID", comment: ""))
            return
        }
    }
    
    func configureUI()
    {
        // Do view setup here.
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        inputUrlTextfield.alignment = NSTextAlignment.left
        inputUrlTextfield.stringValue = ""
        inputUrlTextfield.isEditable = false
        inputUrlTextfield.isEnabled = false
        inputUrlTextfield.layer?.borderWidth = 2.0;
        inputUrlTextfield.layer?.borderColor =  NSColor(colorWithHex: "#D8D8D8", alpha: 1.0)?.cgColor
        inputUrlTextfield.placeholderString = DEFAULT_PERSONAL_LOGIN_URL
        inputUrlTextfield.stringValue = DEFAULT_PERSONAL_LOGIN_URL
        
        inputUrlComboBox.alignment = NSTextAlignment.left
        inputUrlComboBox.stringValue = UserDefaults.standard.string(forKey: "lastRouter") ?? ""
        inputUrlComboBox.removeAllItems()
        if let routers = NXCacheManager.loadRecentRouter(), routers.count > 0 {
            inputUrlComboBox.addItems(withObjectValues: routers)
            inputUrlComboBox.selectItem(at: 0)
        }
        
        inputUrlComboBox.isHidden = false
        inputUrlTextfield.isHidden = true
        
        operationPromptLabel.isHidden = false
        urlTitleLabel.stringValue = NSLocalizedString("TITLE_SETURL_PAGE_URL", comment: "")
        rememberUrlSelectButton.isHidden = false
        
        promptLabel.textColor = NSColor(colorWithHex: "#828282", alpha: 1.0)
        urlTitleLabel.textColor = NSColor(colorWithHex: "#4F4F4F", alpha: 1.0)
        operationPromptLabel.textColor = NSColor(colorWithHex: "#828282", alpha: 1.0)
        
        
        /// change signup button display
        nextButton.wantsLayer = true
        nextButton.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        nextButton.layer?.cornerRadius = 4
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let titleAttr = NSMutableAttributedString(attributedString: nextButton.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, titleAttr.length))
        nextButton.attributedTitle = titleAttr
        // set linear color
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = nextButton.bounds
        gradientLayer.colors = [NSColor(colorWithHex: "#6AB3FA", alpha: 1.0)!.cgColor, NSColor(colorWithHex: "#087FFF", alpha: 1.0)!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        nextButton.layer?.addSublayer(gradientLayer)
        
        
         personalButton.wantsLayer = true
         personalButton.layer?.backgroundColor = NSColor.clear.cgColor
        
        let personalTitle = NSMutableAttributedString(attributedString: personalButton.attributedTitle)
        personalTitle.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, personalTitle.length))
        personalButton.attributedTitle = personalTitle
        
        let companyTitle = NSMutableAttributedString(attributedString: companyButton.attributedTitle)
        companyTitle.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, companyTitle.length))
        companyButton.attributedTitle = companyTitle
        let rememberButtonTitle = NSMutableAttributedString(attributedString: rememberUrlSelectButton.attributedTitle)
        rememberButtonTitle.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, rememberButtonTitle.length))
        rememberUrlSelectButton.attributedTitle = rememberButtonTitle
    
    }
    
    private func showLoading(){
        
        if let maskView = maskView {
            waitingView = NXCommonUtils.createWaitingView(superView: maskView)
            maskView.isHidden = false
            waitingView?.isHidden = false
        }else{
            maskView = NSImageView.init(frame: self.frame)
            maskView?.wantsLayer = true
            maskView?.layer?.backgroundColor = NSColor.white.cgColor
            self.addSubview(maskView!)
            waitingView = NXCommonUtils.createWaitingView(superView: maskView!)
            waitingView?.isHidden = false
            maskView?.isHidden = false
        }
    }
    
    private func hideLoading(){
        maskView?.isHidden = true
        waitingView?.isHidden = true
    }
    
    private func deallocWaitView(){
        maskView = nil
        waitingView = nil
    }
    
    @IBAction func onTapRememberURLButton(_ sender: Any) {
        
    }
    
    @IBAction func onTapPersonalOrCompanyButton(_ sender: Any) {
        switch (sender as! NSButton).tag {
        case 2: self.onTapPersonalButton(sender)
        case 1: self.onTapCompanyButton(sender)
        default : self.onTapCompanyButton(sender)
        }
    }
    
    func onTapPersonalButton(_ sender: Any) {
        urlTitleLabel.stringValue = NSLocalizedString("TITLE_SETURL_PAGE_URL", comment: "")
        operationPromptLabel.isHidden = true
        rememberUrlSelectButton.isHidden = true
        
        inputUrlComboBox.isHidden = true
        inputUrlTextfield.isHidden = false
    }
    
    func onTapCompanyButton(_ sender: Any) {
        urlTitleLabel.stringValue = NSLocalizedString("TITLE_SETURL_PAGE_ENTERURL", comment: "")
        operationPromptLabel.stringValue = NSLocalizedString("MSG_YOU_CAN_CHANGE_URL", comment: "")
        operationPromptLabel.textColor =  NSColor(colorWithHex: "#828282", alpha: 1.0)
        
        operationPromptLabel.isHidden = false
        rememberUrlSelectButton.isHidden = false
        
        inputUrlComboBox.isHidden = false
        inputUrlTextfield.isHidden = true
    }
}

//extension NXTraySetLoginUrlView {
//    fileprivate func setRestApiAddress() {
//        hostURLString = NXCommonUtils.getCurrentRMSAddress()
//    }
//    fileprivate func prepareAfterLogin() {
//        setRestApiAddress()
//    }
//}
