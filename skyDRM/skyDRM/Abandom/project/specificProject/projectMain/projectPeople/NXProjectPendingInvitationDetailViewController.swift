//
//  NXProjectPendingInvitationDetailViewController.swift
//  skyDRM
//
//  Created by xx-huang on 07/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectPendingInvitationDetailViewController: NSViewController {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var invitedTimeLabel: NSTextField!
    @IBOutlet weak var avatarImageView: NSImageView!
    @IBOutlet weak var invitedByLabel: NSTextField!
    @IBOutlet weak var revokeInvitationButton: NSButton!
    @IBOutlet weak var resendInvitationButton: NSButton!
    
    var avatarView: NXAvatarImageView!
    
    weak var delegate:NXProjectPendingInvitationDetailVCDelegate?
    
    fileprivate var projectService: NXProjectAdapter?
    var memberInfo:NXProjectMember?
    var project:NXProject?
    var projectPendingInvitation:NXProjectInvitation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarView = NXAvatarImageView(frame: NSZeroRect)
        avatarImageView.addSubview(avatarView)
        
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!
        
        projectService = NXProjectAdapter(withUserID:userId, ticket:ticket)
        projectService?.delegate = self;
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.styleMask = NSWindow.StyleMask([.closable,.titled])
        self.view.window?.title = NSLocalizedString("TITLE_PENDING_INVITATION", comment: "")
        
        self.configureUI()
        
        revokeInvitationButton.title = "Revoke Invitation"
        revokeInvitationButton.wantsLayer = true
        revokeInvitationButton.layer?.backgroundColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)?.cgColor
        revokeInvitationButton.layer?.cornerRadius = 5
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        
        let titleAttr = NSMutableAttributedString(attributedString: revokeInvitationButton.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, revokeInvitationButton.title.count))
        revokeInvitationButton.attributedTitle = titleAttr
        
        resendInvitationButton.title = "Resend Invitation"
        resendInvitationButton.wantsLayer = true
        resendInvitationButton.layer?.backgroundColor = GREEN_COLOR.cgColor
        resendInvitationButton.layer?.cornerRadius = 5
        
        let resendTitleAttr = NSMutableAttributedString(attributedString: resendInvitationButton.attributedTitle)
        resendTitleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, resendInvitationButton.title.count))
        resendInvitationButton.attributedTitle = resendTitleAttr
        
        let attributeStr = NSMutableAttributedString(string:"Invited by ")
        let inviterNameStr = NSMutableAttributedString(string:memberInfo!.inviterDisplayName!)
        attributeStr.append(inviterNameStr)
        
        let range = NSMakeRange(0, 10)
        attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
        pstyle.alignment = .center
        pstyle.lineBreakMode = .byTruncatingMiddle
        attributeStr.addAttributes([NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, attributeStr.length))
        
        invitedByLabel.attributedStringValue = attributeStr
        
        if !(project?.ownedByMe)! {
            revokeInvitationButton.isHidden = true
            resendInvitationButton.isHidden = true
        }
    }
    
    func configureUI()
    {
        nameLabel.stringValue = (memberInfo?.email)!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy,hh:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let date = NSDate(timeIntervalSince1970:memberInfo!.creationTime)
        let formatJoinTime = formatter.string(from:date as Date)
        
        let attributeStr = NSMutableAttributedString(string:"Invited ")
        let formatJoinTimeStr = NSMutableAttributedString(string:formatJoinTime)
        attributeStr.append(formatJoinTimeStr)
        
        let range = NSMakeRange(0, 7)
        attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        attributeStr.addAttributes([NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, attributeStr.length))
        
        invitedTimeLabel.attributedStringValue = attributeStr
        setDefaultImage(member: memberInfo!)
    }
    
    func setDefaultImage(member:NXProjectMember)
    {
        var displayName:String = ""
        if member.displayName == nil{
            avatarView.circleText?.text = NXCommonUtils.abbreviation(forUserName: (member.email!))
            displayName = member.email!
        }
        else
        {
            avatarView.circleText?.text = NXCommonUtils.abbreviation(forUserName: (member.displayName!))
            displayName = member.displayName!
        }
        
        avatarView.circleText?.extInfo = (member.email!)
        let index = avatarView.circleText?.text.index((avatarView.circleText?.text.startIndex)!, offsetBy: 1)
        if let colorHexValue = NXCommonUtils.circleViewBKColor[String(NXCommonUtils.abbreviation(forUserName: (displayName))[..<index!]).lowercased()]{
            avatarView.circleText?.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
        }else{
            avatarView.circleText?.backgroundColor = NSColor.red
        }
    }
    
    func RevokePendingInvitationTips(){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = NSLocalizedString("REVOKE_PENDING_INVITATION", comment: "")
        myPopup.window.title = NSLocalizedString("TITLE_REVOKE_PENDING", comment: "")
        myPopup.alertStyle = .warning
        myPopup.addButton(withTitle: "Confirm")
        myPopup.addButton(withTitle: "Cancel")
        
        let res = myPopup.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
           projectService?.revokeInvitation(invitation:projectPendingInvitation!)
        }
    }

    
    @IBAction func onTapRevokeButton(_ sender: Any) {
       RevokePendingInvitationTips()
    }
    
    @IBAction func onTapResendInvitationButton(_ sender: Any) {
        if let invitation = self.projectPendingInvitation {
            projectService?.sendInvitationReminder(invitation: invitation)
        }
    }
}

extension NXProjectPendingInvitationDetailViewController : NXProjectAdapterDelegate {
    
    func revokeInvitationFinish(invitation: NXProjectInvitation, error: Error?)
    {
        self.dismiss(self)
         self.delegate?.revokeInvitationFinished(invitation: invitation, error: error)
    }
    
    func sendInvitationReminderFinish(invitation: NXProjectInvitation, error: Error?) {
        self.view.window?.performClose(nil)
        self.delegate?.resendInvitationFinished(error: error)
    }
    
}

