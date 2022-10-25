//
//  NXProjectInviteVC.swift
//  skyDRM
//
//  Created by helpdesk on 3/6/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectInviteVC: NSViewController {
    private weak var emailView: NXEmailView!
    private weak var commentView: NXCommentsView!
    @IBOutlet weak var warningLabel: NSTextField!
    @IBOutlet weak var emailContainerView: NSView!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var inviteBtn: NSButton!
    @IBOutlet weak var projectTitle: NSTextField!
    
    weak var delegate:NXProjectInviteDelegate?
    var projectInfo: NXProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        // Do view setup here.
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame:emailContainerView.bounds, superView: emailContainerView) as? NXEmailView
        
        //set default emails.
        emailView.emailsArray = []
        
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView.placeholder = NSLocalizedString("COMMENT_VIEW_INIVITATION_MSG", comment: "")
        
        if let invitationMsg = projectInfo?.invitationMsg {
            commentView.comments = invitationMsg
        }
        
        inviteBtn.wantsLayer = true
        inviteBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        inviteBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: inviteBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, inviteBtn.title.count))
        inviteBtn.attributedTitle = titleAttr
        
        warningLabel.isHidden = true
        
        projectTitle.stringValue = (projectInfo?.displayName)!
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true;
        self.view.window?.styleMask = .titled
        self.view.window?.backgroundColor = NSColor.white
    }
    
    
    @IBAction func invite(_ sender: Any) {
        warningLabel.isHidden = true
        emailView.currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
        
        guard delegate != nil else{
            return
        }
        guard !emailView.emailsArray.isEmpty else{
            return
        }
        guard projectInfo != nil else{
            return
        }
        
        for item in self.emailView.emailsArray {
            if emailView.isValidate(email: item) == false {
                NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("PROJECT_INVITE_INVALID_EMAIL", comment: ""))
                warningLabel.isHidden = false
                return
            }
        }
        
        self.presentingViewController?.dismiss(self)
        delegate?.onInvite(projectId: (projectInfo?.projectId)!, emailArray: emailView.emailsArray, invitationMsg: commentView.comments)
    }
    @IBAction func onCancelImage(_ sender: Any) {
        presentingViewController?.dismiss(self)
    }
    @IBAction func onCanel(_ sender: Any) {
        presentingViewController?.dismiss(self)
    }
}
