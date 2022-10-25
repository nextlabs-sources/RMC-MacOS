//
//  NXDeclineInvitationVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXDeclineInvitationVC: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var reasonLabel: NSTextField!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var declineBtn: NSButton!
    @IBOutlet weak var warningLabel: NSTextField!
    
    weak var delegate: NXDeclineInvitationVCDelegate?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.styleMask = [.titled, .miniaturizable, .closable]
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_VC_TITLE", comment: "")
        titleLabel.stringValue = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_TITLE", comment: "")
        reasonLabel.placeholderString = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_TOOLTIP", comment: "")
        declineBtn.title = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_DECLINE_BUTTON", comment: "")
        declineBtn.wantsLayer = true
        declineBtn.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        declineBtn.layer?.cornerRadius = 4
        declineBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        declineBtn.layer?.borderWidth = 1
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        var titleAttr = NSMutableAttributedString(attributedString: declineBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, declineBtn.title.count))
        declineBtn.attributedTitle = titleAttr
        
        cancelBtn.title = NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_CANCEL_BUTTON", comment: "")
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        cancelBtn.layer?.cornerRadius = 4
        cancelBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        cancelBtn.layer?.borderWidth = 1
        titleAttr = NSMutableAttributedString(attributedString: cancelBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, cancelBtn.title.count))
        cancelBtn.attributedTitle = titleAttr
        
        reasonLabel.delegate = self
        warningLabel.isHidden = true
        view.window?.delegate = self
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let label = obj.object as? NSTextField {
            if label == self.reasonLabel {
                if reasonLabel.stringValue.count > 250 {
                    NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("PROJECT_PENDING_INVITATIONS_DECLINE_WARNING", comment: ""))
                }
                else {
                    warningLabel.stringValue = ""
                }
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "\u{1b}" {
            close()
        }
        else if event.characters == "\r" {
            onDecline(self)
        }
        else {
            super.keyDown(with: event)
        }
    }
    private func close() {
        presentingViewController?.dismiss(self)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        close()
    }
    @IBAction func onDecline(_ sender: Any) {
        guard reasonLabel.stringValue.count <= 250 else {
            return
        }
        close()
        delegate?.onDecline(reason: reasonLabel.stringValue)
    }
}

extension NXDeclineInvitationVC: NSWindowDelegate {
    private func windowShouldClose(_ sender: Any) -> Bool {
        presentingViewController?.dismiss(self)
        return true
    }
}
