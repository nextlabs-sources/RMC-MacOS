//
//  NXFileShareEmailsView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/6/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol FileShareEmailsViewDelegate : NSObjectProtocol {
    func fileShareEmailsDidChanged(shareEmailsView:NXFileShareEmailsView, emails:[String], shareType:NSInteger)  // shareType 0 mean link, 1 mean attachment
}

class NXFileShareEmailsView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    weak var delegate: FileShareEmailsViewDelegate?
    
    @IBOutlet weak var emailsContainer: NSView!
    
    @IBOutlet weak var promptLabel: NSTextField!
    @IBOutlet weak var shareAsLinkButton: NSButton!
    @IBOutlet weak var shareAsAttachmentButton: NSButton!
    
    @IBAction func shareAsLink(_ sender: Any) {
    }
    
    @IBAction func shareAsAttachment(_ sender: Any) {
        shareAsLinkButton.state = (sender as! NSButton).state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        
        delegate?.fileShareEmailsDidChanged(shareEmailsView: self, emails: emails!, shareType: shareAsLinkButton.state == NSControl.StateValue.off ? 1 : 0)
    }
    
    var emailsView:NXEmailView?
    
    var emails:[String]? {
        set {
            emailsView?.emailsArray = newValue!
        }
        get {
            return emailsView?.vaildEmailsArray
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emailsView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame:emailsContainer.bounds, superView: emailsContainer) as? NXEmailView
        
        emailsContainer .addConstraint(NSLayoutConstraint(item: emailsView ?? emailsView!, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: emailsContainer, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        emailsContainer .addConstraint(NSLayoutConstraint(item: emailsView ?? emailsView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: emailsContainer, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0))
        emailsContainer .addConstraint(NSLayoutConstraint(item: emailsView ?? emailsView!, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: emailsContainer, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        emailsContainer .addConstraint(NSLayoutConstraint(item: emailsView ?? emailsView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: emailsContainer, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0))
    }
}
