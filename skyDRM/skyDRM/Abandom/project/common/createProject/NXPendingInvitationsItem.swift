//
//  NXPendingInvitationsItem.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/18.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXPendingInvitationsDelegate: NSObjectProtocol {
    func onAccept(invitation: NXProjectInvitation)
    func onDecline(invitation: NXProjectInvitation)
}

class NXPendingInvitationsItem: NSCollectionViewItem {

    @IBOutlet weak var inviterLabel: NSTextField!
    @IBOutlet weak var TipLabel: NSTextField!
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var declineBtn: NSButton!
    @IBOutlet weak var acceptBtn: NSButton!
    
    weak var delegate: NXPendingInvitationsDelegate?
    var projectInvitation: NXProjectInvitation! {
        willSet {
            DispatchQueue.main.async {
                if let inviterDisplayName = newValue.inviterDisplayName {
                    self.inviterLabel.stringValue = inviterDisplayName
                }
                self.inviterLabel.toolTip = newValue.inviterEmail
                if let projectDisplayName = newValue.project?.displayName {
                    self.projectNameLabel.stringValue = projectDisplayName
                }
                self.projectNameLabel.toolTip = newValue.project?.projectDescription
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        TipLabel.stringValue = NSLocalizedString("PROJECT_PENDING_INVITATIONS_TIP", comment: "")
        
        acceptBtn.title = NSLocalizedString("PROJECT_PENDING_INVITATIONS_ACCEPT", comment: "")
        acceptBtn.wantsLayer = true
        acceptBtn.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        acceptBtn.layer?.cornerRadius = 4
        acceptBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        acceptBtn.layer?.borderWidth = 1
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let titleAttr1 = NSMutableAttributedString(attributedString: acceptBtn.attributedTitle)
        titleAttr1.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, acceptBtn.title.count))
        acceptBtn.attributedTitle = titleAttr1
        
        declineBtn.title = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE", comment: "")
        declineBtn.wantsLayer = true
        declineBtn.layer?.backgroundColor = NSColor.white.cgColor
        declineBtn.layer?.cornerRadius = 4
        declineBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        declineBtn.layer?.borderWidth = 1
        let titleAttr2 = NSMutableAttributedString(attributedString: declineBtn.attributedTitle)
        titleAttr2.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, declineBtn.title.count))
        declineBtn.attributedTitle = titleAttr2
        
        // Do view setup here.
    }
    @IBAction func onDecline(_ sender: Any) {
        delegate?.onDecline(invitation: projectInvitation)
    }
    
    @IBAction func onAccept(_ sender: Any) {
        delegate?.onAccept(invitation: projectInvitation)
    }
}


