//
//  NXProjectMemberDetailViewController.swift
//  skyDRM
//
//  Created by xx-huang on 06/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectMemberDetailViewController: NSViewController {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var emailLabel: NSTextField!
    @IBOutlet weak var joinTimeLabel: NSTextField!
    @IBOutlet weak var avatarImageView: NSImageView!
    @IBOutlet weak var invitedBySomeOneLabel: NSTextField!
    @IBOutlet weak var removeFromProjectButton: NSButton!
    
    var avatarView: NXAvatarImageView!
    
    weak var delegate:NXProjectMemberDetailVCDelegate?
    
    fileprivate var projectService: NXProjectAdapter?
    var memberInfo:NXProjectMember?
    var project:NXProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarView = NXAvatarImageView(frame: NSZeroRect)
        avatarImageView.addSubview(avatarView)
        
        invitedBySomeOneLabel.isHidden = true
        
        self.removeFromProjectButton.isHidden = !(project?.ownedByMe)!
    
        // Do view setup here.
        
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!
        
        projectService = NXProjectAdapter(withUserID:userId, ticket:ticket)
        projectService?.delegate = self;
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.styleMask = NSWindow.StyleMask([.closable,.titled])
        self.view.window?.title = NSLocalizedString("TITLE_PROJECT_MEMBER_DETAIL", comment: "")
        
        self.configureUI()
        
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        if memberInfo?.userId == userId && (project?.ownedByMe) == true   {
            self.removeFromProjectButton.isHidden = true
            invitedBySomeOneLabel.isHidden = true
        }
        else
        {
            projectService?.getMemberDetails(project: project!, member: memberInfo!)
        }
        
        removeFromProjectButton.title = "Remove From Project"
        removeFromProjectButton.wantsLayer = true
        removeFromProjectButton.layer?.backgroundColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)?.cgColor
        removeFromProjectButton.layer?.cornerRadius = 5
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        
        let titleAttr = NSMutableAttributedString(attributedString: removeFromProjectButton.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, removeFromProjectButton.title.count))
        removeFromProjectButton.attributedTitle = titleAttr
    }
    
    deinit {
        
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
    }
    
    @IBAction func onTapRemoveButton(_ sender: Any) {
         self.RemoveMemberTips(member: memberInfo!, project: project!)
    }
    
    func configureUI()
    {
        nameLabel.stringValue = (memberInfo?.displayName)!
        emailLabel.stringValue = (memberInfo?.email)!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy,hh:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let date = NSDate(timeIntervalSince1970:memberInfo!.creationTime)
        let formatJoinTime = formatter.string(from:date as Date)
        
        let attributeStr = NSMutableAttributedString(string:"Joined on ")
        let formatJoinTimeStr = NSMutableAttributedString(string:formatJoinTime)
        attributeStr.append(formatJoinTimeStr)
        
        let range = NSMakeRange(0, 9)
        attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        attributeStr.addAttributes([NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, attributeStr.length))

        joinTimeLabel.attributedStringValue = attributeStr
        setDefaultImage(member:memberInfo!)
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
    
    func RemoveMemberTips(member:NXProjectMember,project:NXProject){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = NSLocalizedString("REMOVE_MEMBER_TIPS", comment: "")
        
        myPopup.window.title = NSLocalizedString("TITLE_REMOVE_MEMBER_TIPS", comment: "")
        
        myPopup.alertStyle = .warning
        myPopup.addButton(withTitle: "Confirm")
        myPopup.addButton(withTitle: "Cancel")
        
        let res = myPopup.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            projectService?.removeMember(project: project, member: member)
        }
    }
}

extension NXProjectMemberDetailViewController : NXProjectAdapterDelegate {
    func getMemberDetailsFinish(projectId: String, member: NXProjectMember?, error: Error?) {
        if member?.inviterDisplayName?.isEmpty == false {
            invitedBySomeOneLabel.isHidden = false
            let attributeStr = NSMutableAttributedString(string:"Invited by ")
            let inviterNameStr = NSMutableAttributedString(string:member!.inviterDisplayName!)
            attributeStr.append(inviterNameStr)
            
            let range = NSMakeRange(0, 10)
            attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
            
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            pstyle.lineBreakMode = .byTruncatingMiddle
            attributeStr.addAttributes([NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, attributeStr.length))
            
            invitedBySomeOneLabel.attributedStringValue = attributeStr
        }
        else
        {
             invitedBySomeOneLabel.isHidden = true
        }
    }
    
    func removeMemberFinish(projectId: String, member: NXProjectMember, error: Error?) {
        self.dismiss(self)
        self.delegate?.removeMemberFromProjectFinished(error:error, member: member)
    }
}

