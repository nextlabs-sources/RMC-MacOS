//
//  NXAccountLogoutView.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 16/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXAccountLogoutView: NXProgressIndicatorView, NXUserServiceDelegate {
    
    @IBOutlet weak var logoutBtn: NSButton!
    @IBOutlet weak var emailLabel: NSTextField!
    @IBOutlet weak var avaterView: NXCircleText!
    @IBOutlet weak var changePwdBtn: NSButton!
    @IBOutlet weak var changePhotoBtn: NSButton!
    @IBOutlet weak var manageBtn: NSButton!
    @IBOutlet weak var btnStackView: NSStackView!
    
    weak var delegate: NXAccountActionDelegate?
    
    private var avatarBase64String: String!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            let displayName = profile.displayName ?? profile.userName ?? ""
            let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
            avaterView.text = abbrevStr
            avaterView.extInfo = profile.email
            avaterView.font = NSFont.systemFont(ofSize: 40)
            
            let index = displayName.index(displayName.startIndex, offsetBy: 1)
            let firstStr = String(abbrevStr[..<index]).lowercased()
            if let colorHexValue = NXCommonUtils.circleViewBKColor[firstStr]{
                avaterView.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
            }
        }
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview != nil {
            
            do{
                let type:Int = try NXLClient.currentNXLClient().idpType.rawValue
                
                if type == 0 {
                    changePwdBtn.isHidden = false
                }
                else
                {
                    changePwdBtn.isHidden = true
                    
                    let constX:NSLayoutConstraint = NSLayoutConstraint(item: manageBtn as Any, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: btnStackView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0);
                    self.addConstraint(constX);
                }
            }  catch let error as NSError {
                Swift.print("get NXLClient failed : \(error)")
            }
            
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.white.cgColor
            logoutBtn.wantsLayer = true
            logoutBtn.layer?.backgroundColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)?.cgColor
            logoutBtn.layer?.cornerRadius = 5
            logoutBtn.title = NSLocalizedString("ACCOUNT_LOGOUT", comment: "")
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            let titleAttr = NSMutableAttributedString(attributedString: logoutBtn.attributedTitle)
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, logoutBtn.title.count))
            logoutBtn.attributedTitle = titleAttr
            changePwdBtn.title = NSLocalizedString("ACCOUNT_CHANGE_PASSWORD", comment: "")
            manageBtn.title = NSLocalizedString("ACCOUNT_MANAGE_PROFILE", comment: "")
            
            changePhotoBtn.wantsLayer = true
            changePhotoBtn.title = NSLocalizedString("ACCOUNT_CHANGE_PHOTO", comment: "")
            let photoPstyle = NSMutableParagraphStyle()
            photoPstyle.alignment = .center
            let photoTitleAttr = NSMutableAttributedString(attributedString: changePhotoBtn.attributedTitle)
            photoTitleAttr.addAttributes([NSAttributedString.Key.foregroundColor: GREEN_COLOR, NSAttributedString.Key.paragraphStyle: photoPstyle], range: NSMakeRange(0, changePhotoBtn.title.count))
            
            changePhotoBtn.attributedTitle = photoTitleAttr
            changePhotoBtn.cell?.isHighlighted = false
            
            changePhotoBtn.isHidden = true
            
            guard let profile = NXLoginUser.sharedInstance.nxlClient?.profile else {
                return
            }
            var image: NSImage!
            if let profileImage = NSImage(base64String: profile.avatar)  {
                image = profileImage
            }
            else if let profileImage = NSImage(named: "avatar") {
                image = profileImage
            }
            setInfo(avatar: image, email: profile.email)
            
        }
    }
    private func setInfo(avatar: NSImage, email: String){
        emailLabel.stringValue = email
    }
    private func updateAvatar() {
        
        guard  let userID = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket else {
                return
        }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.allowedFileTypes = ["jpg", "png"]
        
        guard let window = self.window else {
            return
        }
        openPanel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else {
                    return
                }
                let image = NSImage(byReferencing: url)
                guard let data = NSImage.zipImage(image: image, fileSize: 16*1024),
                    let base64Str = NSImage(data: data)?.base64String else {
                        return
                }
                self.startAnimation()
                let userService = NXUserService(userID: userID, ticket: ticket)
                userService.delegate = self
                userService.updateAvatar(avatar: base64Str)
                self.avatarBase64String = base64Str
            }
        }

    }
    @IBAction func onClose(_ sender: Any) {
        delegate?.accountCloseLogoutView()
    }
    @IBAction func onLogout(_ sender: Any) {
        let cancel = NSLocalizedString("ACCOUNT_LOGOUT_ALERT_CANCEL", comment: "")
        let confirm = NSLocalizedString("ACCOUNT_LOGOUT_ALERT_OK", comment: "")
        let msg = NSLocalizedString("ACCOUNT_LOGOUT_ALERT", comment: "")
        NSAlert.showAlert(withMessage: msg, confirmButtonTitle: confirm, cancelButtonTitle: cancel, dismissClosure: { type in
            if type == .sure {
                self.delegate?.accountLogout()
            }
        })
    }
    @IBAction func onChangePassword(_ sender: Any) {
        delegate?.accountOpenChangeView()
    }

    @IBAction func onChangePhoto(_ sender: Any) {
        updateAvatar()
    }
    @IBAction func onManageProfile(_ sender: Any) {
        delegate?.accountOpenManageView()
    }
    
    func updateAvatarFinished(error: Error?) {
        defer {
            stopAnimation()
        }
        if error == nil {
            if let profile = NXLoginUser.sharedInstance.nxlClient?.profile,
                let image = NSImage(base64String: avatarBase64String) {
                DispatchQueue.main.async {
                    self.setInfo(avatar: image, email: profile.email)
                }
                profile.avatar = avatarBase64String
                NXLKeyChain.update("NXLKeychainKey", data: NXLoginUser.sharedInstance.nxlClient)
            }
            delegate?.accountChangeAvatar()
            //FIXME: will update profile in keychain
        }
    }

}

