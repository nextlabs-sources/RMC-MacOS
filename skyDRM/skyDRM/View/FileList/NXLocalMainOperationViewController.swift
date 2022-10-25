//
//  NXLocalMainOperationViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 17/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum NXMainOperationBarOperationType {
    case protect
    case share
    case selectCategory
    case refresh
    case search
    case startUploadAll
    case stopUploadAll
    case openNetwork
    case openPreference
}

enum NXFromType {
    case myVault
    case project
}

protocol NXLocalMainOperationViewControllerDelegate: class {
    func operationClicked(type: NXMainOperationBarOperationType, value: Any?)
}

class NXLocalMainOperationViewController: NSViewController {

    fileprivate struct Constants {
        static let offlineColor = NSColor(colorWithHex: "#EB5757", alpha: 1)!
        static let onlineColor = NSColor(colorWithHex: "#27AE60", alpha: 1)!
    }
    
    @IBOutlet weak var groupTypeBtn: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var portraitView: NXCircleText!
    @IBOutlet weak var nameLbl: NSTextField!
    @IBOutlet weak var statusLbl: NSTextField!
    @IBOutlet weak var uploadBtn: NSButton!
    @IBOutlet weak var refreshBtn: NSButton!
    @IBOutlet weak var protectFile: NSButton!
    @IBOutlet weak var protectAndShare: NSButton!
    
    @IBOutlet weak var openWebsiteButton: NSButton!
    
    @IBOutlet weak var preferenceButton: NSButton!
    
    weak var delegate: NXLocalMainOperationViewControllerDelegate?
    
    var fromType: NXFromType? {
        didSet {
            protectFile.highlight(true)
            protectFile.appearance = NSAppearance(named: .aqua)
            protectFile.layer?.backgroundColor = NSColor.clear.cgColor
            protectFile.isTransparent = false
         
            protectAndShare.highlight(fromType == .myVault ? true : false)
            protectAndShare.isEnabled = fromType == .myVault ? true : false
            protectAndShare.appearance = NSAppearance(named: .aqua)
            protectAndShare.layer?.backgroundColor = NSColor.clear.cgColor
            protectAndShare.isTransparent = false
            protectAndShare.highlight(fromType == .myVault ? true : false)
            
        }
    }
    
    var animation: CABasicAnimation = {
        let anima = CABasicAnimation.init(keyPath: "transform.rotation")
        anima.fromValue = NSNumber.init(value: 0)
        anima.toValue = -2.0 * Double.pi
        anima.duration = 0.7
        
        anima.repeatCount = MAXFLOAT
        anima.isRemovedOnCompletion = false
        return anima
    }()
    
    var isRefreshing = false
    
    var isMyvaultRefresh = false
    var isShareWithMeRefresh = false
    var isProjectRefresh = false
    var isWorkspaceRefresh = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Custom UI.
        initView()
        //internationalization suitable
        location()
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if self.refreshBtn.layer?.anchorPoint.x == 0 {
            setAnchorPoint()
        }
    }
    
    func setAnchorPoint() {
        self.refreshBtn?.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let point = (self.refreshBtn?.layer?.position)!
        self.refreshBtn?.layer?.position = CGPoint(x: point.x + self.refreshBtn.bounds.width/2, y: point.y + self.refreshBtn.bounds.height/2)
    }
    
    func initView() {
        uploadBtn.state = NXClientUser.shared.setting.getIsAutoUpload() ? NSControl.StateValue.on : NSControl.StateValue.off
        changeUploadBtnTitleImage(state: NXClientUser.shared.setting.getIsAutoUpload())
        NotificationCenter.add(self, selector: #selector(startRefresh(_:)), notification: .startRefresh)
        NotificationCenter.add(self, selector: #selector(stopRefresh(_:)), notification: NXNotification.stopRefresh)
        NotificationCenter.add(self, selector: #selector(stopUploadAllFinish), notification: .stopUploadAllFinish)
        protectFile.highlight(true)
        protectAndShare.highlight(true)
        
        NotificationCenter.add(self, selector: #selector(changeButtonState(_ :)), notification: .closeSelectFilePanel)

        self.refreshBtn.wantsLayer = true
    }
    
    @objc func changeButtonState(_ notifi: Notification) {
        protectFile.highlight(true)
        if fromType == .myVault || fromType == nil {
            protectAndShare.highlight(true)
        }
    }
    
    fileprivate func location(){
        protectFile.title = "FILE_OPERATION_PROTECT_FILE".localized
        protectAndShare.title = "FILE_OPERATION_PROTECT_AND_SHARED".localized
        openWebsiteButton.toolTip = "BUTTON_TOOPTIP_OPEN_SKYDRM_WEB".localized
        preferenceButton.toolTip =  "BUTTON_TOOPTIP_PREFERENCES".localized
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        updateUserInfo()
        // Display network status
        
        updateNetworkStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func startRefresh(_ notification: Notification) {
        if let type = notification.object as? NXDriverType {
            switch type {
            case .myVault:
                isMyvaultRefresh = true
            case .shareWithMe:
                isShareWithMeRefresh = true
            case .allProject,
                 .project:
                isProjectRefresh = true
            case .workspace:
                isWorkspaceRefresh = true
            default:
                break
                
            }
        }
         
        startRefresh()
        
    }
    
    @objc func stopRefresh(_ notification: Notification) {
        if let type = notification.object as? NXDriverType {
            switch type {
            case .myVault:
                isMyvaultRefresh = false
            case .shareWithMe:
                isShareWithMeRefresh = false
            case .allProject,
                 .project:
                isProjectRefresh = false
            case .workspace:
                isWorkspaceRefresh = false
            default:
                break
                
            }
        }
        
        stopRefresh()
    }
    
    func startRefresh() {
        isRefreshing = true
        self.refreshBtn?.layer?.add(self.animation, forKey: nil)
    }
    
    func stopRefresh() {
        isRefreshing = false
        self.refreshBtn?.layer?.removeAllAnimations()
    }
    
    func updateRefreshButton(type: selectecType) {
        let checkRefresh: (Bool) -> () = { isRefresh in
            if isRefresh {
                self.startRefresh()
            } else {
                self.stopRefresh()
            }
        }
        switch type {
        case .myVault:
            checkRefresh(isMyvaultRefresh)
        case .sharedWithMe:
            checkRefresh(isShareWithMeRefresh)
        case .project,
             .projectFolder,
             .projectFile:
            checkRefresh(isProjectRefresh)
        case .workspace:
            checkRefresh(isWorkspaceRefresh)
        default:
            stopRefresh()
        }
    }
    
    func updateUserInfo() {
        if let user = NXClientUser.shared.user {
            let displayName = user.name
            nameLbl.stringValue = user.name
            portraitView.text = NXCommonUtils.abbreviation(forUserName: displayName)
            portraitView.extInfo = user.email
            let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
            let index = displayName.index(displayName.startIndex, offsetBy: 1)
            let firstStr = String(abbrevStr[..<index]).lowercased()
            if let colorHexValue = NXCommonUtils.circleViewBKColor[firstStr]{
                portraitView.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
            }
        }
    }
    
    func updateNetworkStatus() {
        let status = NXClientUser.shared.isOnline
        displayNetworkStatus(with: status)
    }
    
    func displayNetworkStatus(with isConnect: Bool) {
        if isConnect {
            let attributes = [NSAttributedString.Key.foregroundColor: Constants.onlineColor]
            let attributedStr = NSAttributedString.init(string: "NETWORK_STATUS_ONLINE".localized, attributes: attributes)
            statusLbl.attributedStringValue = attributedStr
        } else {
            let attributes = [NSAttributedString.Key.foregroundColor: Constants.offlineColor]
            let attributedStr = NSAttributedString.init(string: "NETWORK_STATUS_OFFLINE".localized, attributes: attributes)
            statusLbl.attributedStringValue = attributedStr
        }
    }
    
    @IBAction func protectFile(_ sender: Any) {
        delegate?.operationClicked(type: .protect, value: nil)
        
    }
    
    @IBAction func shareFile(_ sender: Any) {
        delegate?.operationClicked(type: .share, value: nil)
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        if isRefreshing {
            return
        }
        
        delegate?.operationClicked(type: .refresh, value: nil)
    }
    
    @IBAction func changeUpload(_ sender: Any) {
        let state = uploadBtn.state == NSControl.StateValue.on ? true : false
        // on -> off: make sure all cancel finish.
        // off -> on: immediate.
        if state {
            NXClientUser.shared.setting.setIsAutoUpload(value: true)
            changeUploadBtnTitleImage(state: true)
        } else {
            NXClientUser.shared.setting.setIsAutoUpload(value: false)
            uploadBtn.isEnabled = false
        }
        
        delegate?.operationClicked(type: state ? .startUploadAll : .stopUploadAll, value: nil)
    }
    
    private func changeUploadBtnTitleImage(state: Bool) {
        uploadBtn.title = state ? "LOCAL_MAIN_OPERATIONBAR_STOPALL".localized : "LOCAL_MATN_OPERATIONBAR_START".localized
        uploadBtn.image = state ? NSImage(named:"StopUpload-ToolBarIcon") : NSImage(named: "StartUpload-ToolBarIcon")
    }
    
    @objc func stopUploadAllFinish() {
        uploadBtn.isEnabled = true
        changeUploadBtnTitleImage(state: false)
    }
    
    @IBAction func changeGroupType(_ sender: Any) {
        delegate?.operationClicked(type: .selectCategory, value: groupTypeBtn.titleOfSelectedItem)
    }
    
    @IBAction func changeSearchContent(_ sender: Any) {
        delegate?.operationClicked(type: .search, value: searchField.stringValue)
    }
    
    @IBAction func openWeb(_ sender: Any) {
        delegate?.operationClicked(type: .openNetwork, value: nil)
    }
    
    @IBAction func openPreference(_ sender: Any) {
        delegate?.operationClicked(type: .openPreference, value: nil)
    }
    
}
