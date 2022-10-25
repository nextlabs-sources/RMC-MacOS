//
//  NXProjectMemberCellItem.swift
//  skyDRM
//
//  Created by xx-huang on 03/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectMemberCellItem: NSCollectionViewItem {
 
    @IBOutlet weak var avatarView: NSImageView!
    var avatarImageView: NXAvatarImageView!

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var joinedTimeLabel: NSTextField!
    
    @IBOutlet weak var ownerImageView: NSImageView!
    
    weak var delegate:NXProjectMemberCellItemDelegate?
    
    var projectMemberModel:NXProjectMember?
    var projectPendingInvitation:NXProjectInvitation?
    
    var isInvitation:Bool = false
    
    @IBOutlet weak var bkButton: NSButton!
    fileprivate var trackingArea: NSTrackingArea!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        joinedTimeLabel.isHidden = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        avatarImageView = NXAvatarImageView(frame: NSZeroRect)
        avatarView.addSubview(avatarImageView)
        
        if trackingArea != nil {
            bkButton.removeTrackingArea(trackingArea)
        }
        let trackingRect = bkButton.bounds
        trackingArea = NSTrackingArea(rect: trackingRect, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        bkButton.addTrackingArea(trackingArea)

    }
    
    var memberInfo: NXProjectMember?{
        didSet{
            guard isViewLoaded else{
                return
            }
            isInvitation = false
            projectMemberModel = memberInfo
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
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
            
            if let memberInfo = memberInfo{
                nameLabel.stringValue = memberInfo.displayName!
                joinedTimeLabel.attributedStringValue = attributeStr
                setDefaultImage(member: memberInfo)
            }
            else
            {
                nameLabel.stringValue = ""
                joinedTimeLabel.stringValue = ""
            }
        }
    }
    
    var invitationInfo: NXProjectInvitation?{
        didSet {
            guard isViewLoaded else{
                return
            }
            
            isInvitation = true
            projectPendingInvitation = invitationInfo
            let memberModel:NXProjectMember = NXProjectMember()
            
            memberModel.email = invitationInfo?.inviteeEmail
            memberModel.creationTime = (invitationInfo?.inviteTime)!
            memberModel.inviterEmail = invitationInfo?.inviterEmail
            memberModel.inviterDisplayName = invitationInfo?.inviterDisplayName
            
            projectMemberModel = memberModel
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let date = NSDate(timeIntervalSince1970:projectPendingInvitation!.inviteTime)
            let formatJoinTime = formatter.string(from:date as Date)
            
            let attributeStr = NSMutableAttributedString(string:"Invited on ")
            let formatJoinTimeStr = NSMutableAttributedString(string:formatJoinTime)
            attributeStr.append(formatJoinTimeStr)
            
            let range = NSMakeRange(0, 10)
            attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
            
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            attributeStr.addAttributes([NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, attributeStr.length))
            
            if let inviteInfo = invitationInfo{
                nameLabel.stringValue = inviteInfo.inviteeEmail!
                joinedTimeLabel.attributedStringValue = attributeStr
                
                setDefaultImage(member: memberModel)
            }
            else
            {
                nameLabel.stringValue = ""
                joinedTimeLabel.stringValue = ""
            }
        }
    }
    
    func setDefaultImage(member:NXProjectMember)
    {
        var displayName:String = ""
        if member.displayName == nil{
            avatarImageView.circleText?.text = NXCommonUtils.abbreviation(forUserName: (member.email!))
            displayName = member.email!
        }
        else
        {
            avatarImageView.circleText?.text = NXCommonUtils.abbreviation(forUserName: (member.displayName!))
            displayName = member.displayName!
        }
        
        avatarImageView.circleText?.extInfo = (member.email!)
        let index = avatarImageView.circleText?.text.index((avatarImageView.circleText?.text.startIndex)!, offsetBy: 1)
        if let colorHexValue = NXCommonUtils.circleViewBKColor[String(NXCommonUtils.abbreviation(forUserName: (displayName))[..<index!]).lowercased()]{
            avatarImageView.circleText?.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
        }else{
            avatarImageView.circleText?.backgroundColor = NSColor.red
        }
    }
    
    @IBAction func onTapBkButton(_ sender: Any) {
        
        delegate?.onClickMemberCellItem(memberModel: projectMemberModel,pendingInvitation:projectPendingInvitation,isInvitation:isInvitation)
    }
    //mouse event
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        debugPrint("mouse down")
        super.mouseDown(with: event)
    }
}
