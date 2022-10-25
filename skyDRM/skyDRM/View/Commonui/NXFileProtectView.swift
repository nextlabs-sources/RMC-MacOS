//
//  NXFileProtectView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum NXFileProtectType {
    case protect
    case share
}

protocol NXFileProtectViewDelegate: NSObjectProtocol {
    func protectAction(forFile file:NXFileBase?, withRights rights:NXLRights?)
    func shareAction(forFile file:NXFileBase?, withRights rights:NXLRights?, emails:[String]?, shareType: NSInteger?, comment: String?) // 0 mean link
    func cancelAction(forFile file:NXFileBase?, withProtectType type:NXFileProtectType?)
}

class NXFileProtectView: NSView {
    
    @IBOutlet weak var shareEmailContainer:NSView!
    @IBOutlet weak var rightsContainer:NSView!
    @IBOutlet weak var commentsContainer: NSView!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var bevelButton: NSButton!
    var rightsSelectView: NXRightsView?;
    var shareWithOtherButton:NSButton?
    var shareEmailsView:NXFileShareEmailsView?
    var shareCommentsView: NXFileShareCommentsView?
    var progressValue :Double? = 0 { //range 0-1
        didSet {
            if progressValue! - 0.99 > 0 {
                progressIndicator.isHidden = true
            } else {
                progressIndicator.isHidden = false
            }
            progressIndicator.doubleValue = progressValue! * 100
        }
    }
    
    @IBAction func confirmClick(_ sender: NSButton) {
        
        if fileProtectType == .share {
            if (self.shareEmailsView?.emailsView?.emailsArray.count)! >= 1 {
                for item in (self.shareEmailsView?.emailsView?.emailsArray)! {
                    if self.shareEmailsView?.emailsView?.isValidate(email: item) == false {
                        NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_EXIST_INVALID_EMAIL", comment: ""))
                        return
                    }
                }
            }
            
            shareEmailsView?.emailsView?.currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
        } else {
        }
        
    }
    @IBAction func cancelClick(_ sender: NSButton) {
        delegate?.cancelAction(forFile: fileItem, withProtectType: fileProtectType!)
    }
    @IBAction func closeClicked(_ sender: NSButton) {
        delegate?.cancelAction(forFile: fileItem, withProtectType: fileProtectType!)
    }
    @objc private func shareWithOtherClick(_ sender: NSButton) {
        fileProtectType = .share
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        __NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
    
    override func viewDidMoveToSuperview() {
        confirmButton.wantsLayer = true
        confirmButton.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        confirmButton.layer?.cornerRadius = 4
        confirmButton.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        confirmButton.layer?.borderWidth = 1
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
    
        cancelButton.wantsLayer = true
        cancelButton.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
        cancelButton.layer?.cornerRadius = 4
        cancelButton.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        cancelButton.layer?.borderWidth = 1
        cancelButton.stringValue = NSLocalizedString("Cancel", comment: "")
        
        bevelButton.isHidden = true
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        if rightsSelectView != nil  {
            rightsSelectView?.removeFromSuperview()
            rightsSelectView = nil
        }
        if shareEmailsView != nil {
            shareEmailsView?.removeFromSuperview()
            shareEmailsView = nil
        }
        if shareCommentsView != nil {
            shareCommentsView?.removeFromSuperview()
            shareCommentsView = nil
        }
    }
    
    class func createFileProtectView(frame frameRect: NSRect, withFile file:NXFileBase, type:NXFileProtectType)->NXFileProtectView {
       let protectView = NXCommonUtils.createViewFromXib(xibName: "NXFileProtectView", identifier: "NXFileProtectView", frame: frameRect, superView: nil) as! NXFileProtectView
        protectView.fileItem = file;
        protectView.fileProtectType = type
        protectView.progressIndicator.isHidden = true
        protectView.doWork()
        return protectView
    }
    
    weak var delegate : NXFileProtectViewDelegate?
    
    var fileItem: NXFileBase?
    
//    fileprivate var emails:[String]?
    fileprivate var shareType:NSInteger? = 0
    
    private var _fileProtectType : NXFileProtectType! = NXFileProtectType.protect
    var fileProtectType : NXFileProtectType? {
        get {
            return _fileProtectType
        }
        
        set {
            _fileProtectType = newValue
            self.protectTypeDidChanged()
        }
    }
    
    func isNXLFile(ofFile file:NXFileBase?)->Bool {
        guard let _ = file, let _ = file?.localPath else {
            Swift.print("fileItem is have no cache")
            return false
        }
        
        //TODO
        return false
    }
    
    func doWork(){
        if fileProtectType == .protect {
            nameLabel.stringValue = "Protect - " + (fileItem?.name)!
        } else if fileProtectType == .share {
            nameLabel.stringValue = "Share - " + (fileItem?.name)!
        }
        
        rightsSelectView = NXCommonUtils.createViewFromXib(xibName: "NXRightsView", identifier: "rightsView", frame: rightsContainer.bounds, superView: rightsContainer) as! NXRightsView?
        
        // Init watermark and expiry from preference.
        var watermark: NXFileWatermark?
        var expiry: NXFileExpiry?
        if let text = NXClient.getCurrentClient().getUserPreference()?.getDefaultWatermark().getText() {
            watermark = NXFileWatermark(text: text)
        }
        if let preferenceExpiry = NXClient.getCurrentClient().getUserPreference()?.getDefaultExpiry() {
            expiry = NXCommonUtils.transform(from: preferenceExpiry)
        }
        rightsSelectView?.set(watermark: watermark, expiry: expiry)
        
        rightsSelectView?.translatesAutoresizingMaskIntoConstraints = false
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsSelectView!, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsSelectView!, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsSelectView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsSelectView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0))
    }
    
    private func protectTypeDidChanged() {
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        if fileProtectType == .protect {
            confirmButton.attributedTitle = NSAttributedString(string: NSLocalizedString("Protect", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : pstyle, NSAttributedString.Key.font:NSFont.systemFont(ofSize: 15)])
            heightConstraint.constant = 1;
            commentsHeightConstraint.constant = 1
        }
        
        if fileProtectType == .share {
            confirmButton.attributedTitle = NSAttributedString(string: NSLocalizedString("Share", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : pstyle, NSAttributedString.Key.font:NSFont.systemFont(ofSize: 15)])
            
            shareEmailContainer?.subviews.forEach({ $0.removeFromSuperview() })
            
            shareEmailsView = NXCommonUtils.createViewFromXib(xibName: "NXFileShareEmailsView", identifier: "NXFileShareEmailsView", frame: shareEmailContainer.bounds, superView: shareEmailContainer) as! NXFileShareEmailsView?
            shareEmailsView?.delegate = self
            
            shareEmailContainer.addSubview(shareEmailsView!)
    
            shareEmailsView?.translatesAutoresizingMaskIntoConstraints = false
            
            shareEmailContainer.addConstraint(NSLayoutConstraint(item: shareEmailsView ?? shareEmailsView!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: shareEmailContainer, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0))
            shareEmailContainer.addConstraint(NSLayoutConstraint(item: shareEmailsView ?? shareEmailsView!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: shareEmailContainer, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0))
            shareEmailContainer.addConstraint(NSLayoutConstraint(item: shareEmailsView ?? shareEmailsView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: shareEmailContainer, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
            shareEmailContainer.addConstraint(NSLayoutConstraint(item: shareEmailsView ?? shareEmailsView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: shareEmailContainer, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
            
            shareCommentsView?.subviews.forEach({ $0.removeFromSuperview() })
            shareCommentsView = NXCommonUtils.createViewFromXib(xibName: "NXFileShareCommentsView", identifier: "fileShareCommentsView", frame: nil, superView: commentsContainer) as? NXFileShareCommentsView
            shareCommentsView?.translatesAutoresizingMaskIntoConstraints = false
            
            commentsContainer.addConstraint(NSLayoutConstraint(item: shareCommentsView ?? shareCommentsView!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: commentsContainer, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0))
            commentsContainer.addConstraint(NSLayoutConstraint(item: shareCommentsView ?? shareCommentsView!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: commentsContainer, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0))
            commentsContainer.addConstraint(NSLayoutConstraint(item: shareCommentsView ?? shareCommentsView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: commentsContainer, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
            commentsContainer.addConstraint(NSLayoutConstraint(item: shareCommentsView ?? shareCommentsView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: commentsContainer, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
            
            heightConstraint.constant = 200
            commentsHeightConstraint.constant = 180
        }
    }
    
}

extension NXFileProtectView : FileShareEmailsViewDelegate {
    func fileShareEmailsDidChanged(shareEmailsView:NXFileShareEmailsView, emails:[String], shareType:NSInteger) {
        self.shareType = shareType
    }
}
