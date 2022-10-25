//
//  NXDisconnectRepoView.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXDisconnectRepoView: NSView {

    @IBOutlet weak var disconnectBtn: NSButton!
    @IBOutlet weak var typeLabel: NSTextField!
    @IBOutlet weak var accountLabel: NSTextField!
    @IBOutlet weak var aliasLabel: NSTextField!
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    weak var delegate: NXDisconnectRepoViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if superview != nil {
            self.wantsLayer = true
            self.layer?.backgroundColor = BK_COLOR.cgColor
            
            titleLabel.stringValue = NSLocalizedString("REPOSITORY_MANAGE", comment: "")
            image.imageScaling = .scaleAxesIndependently
            disconnectBtn.wantsLayer = true
            disconnectBtn.layer?.backgroundColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)?.cgColor
            disconnectBtn.layer?.cornerRadius = 5
            disconnectBtn.title = NSLocalizedString("REPOSITORY_DISCONNECT", comment: "")
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            let titleAttr = NSMutableAttributedString(attributedString: disconnectBtn.attributedTitle)
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, disconnectBtn.title.count))
            disconnectBtn.attributedTitle = titleAttr
            
            aliasLabel.textColor = NSColor(colorWithHex: "#249FF4", alpha: 1.0)
            typeLabel.textColor = NSColor(colorWithHex: "#828282", alpha: 1.0)
        }
    }
    
    @IBAction func onGoback(_ sender: Any) {
        delegate?.onGoback()
    }
    @IBAction func onDisconnect(_ sender: Any) {
        let msg = String(format: NSLocalizedString("REPOSITORY_DISCONNECT_ALERT", comment: ""), aliasLabel.stringValue)
        let confirm = NSLocalizedString("REPOSITORY_DISCONNECT_ALERT_OK", comment: "")
        let cancel = NSLocalizedString("REPOSITORY_DISCONNECT_ALERT_CANCEL", comment: "")
        NSAlert.showAlert(withMessage: msg, confirmButtonTitle: confirm, cancelButtonTitle: cancel, dismissClosure: { type in
            if type == .sure {
                self.delegate?.onDisconnect()
            }
        })
    }
    func setInfo(image: NSImage, alias: String, account: String, type: String) {
        self.image.image = image
        self.aliasLabel.stringValue = alias
        self.accountLabel.stringValue = account
        self.typeLabel.stringValue = type
    }
    func setAlias(alias: String) {
        self.aliasLabel.stringValue = alias
    }
}
