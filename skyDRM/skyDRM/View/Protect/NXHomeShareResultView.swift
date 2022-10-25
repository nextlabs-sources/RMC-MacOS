//
//  NXHomeShareResultView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeShareResultViewDelegate: NSObjectProtocol {
    func closeShareResult(files: [NXNXLFile])
}

class NXHomeShareResultView: NSView {

    @IBOutlet var nameTextView: NSTextView!
    @IBOutlet weak var rightsContainerView: NSView!
    @IBOutlet weak var emailContainerView: NSView!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet weak var backgroundView: NSView!
    
    @IBOutlet var fileNameTextfieldLabel: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    weak var delegate: NXHomeShareResultViewDelegate?
    
    var files: [NXNXLFile]! {
        didSet {
                var displayName = self.files.reduce("", { (str1, file) -> String in
                    return str1 + "\n" + file.name
                })
                displayName.removeFirst()
                
                self.nameTextView.string = displayName
                
                if self.files.count > 1 {
                    self.titleLbl.stringValue = "Share protected files"
                }
        }
    }
    
    var emails = [String]() {
        willSet {
            emailView?.emailsArray = newValue
        }
    }
    
    var comments = "" {
        willSet {
            commentView?.comments = newValue
        }
    }
    
    var rights: NXRightObligation? {
        didSet {
            rightView?.right = rights
        }
    }
    
    fileprivate var emailView: NXEmailView?
    fileprivate var commentView: NXCommentsView?
    fileprivate var rightView: NXRightViewOnly?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")!.cgColor
        nameTextView.textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0)
        
        rightView = NXCommonUtils.createViewFromXib(xibName: "NXRightViewOnly", identifier: "rightViewOnly", frame: nil, superView: rightsContainerView) as? NXRightViewOnly
        
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame: nil, superView: emailContainerView) as? NXEmailView
        emailView?.isEnable = false
        
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView?.placeholder = NSLocalizedString("COMMENT_VIEW_SHARE_COMMENT", comment: "")
        commentView?.isEnable = false
        commentView?.text.isEditable = false
        commentView?.text.isSelectable = false
        commentView?.indicatorLabel.isEditable = false
       fileNameTextfieldLabel.isSelectable = false
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.borderWidth = 1
        backgroundView.layer?.borderColor = NSColor(colorWithHex: "#BDBDBD")!.cgColor
        backgroundView.layer?.backgroundColor = NSColor(colorWithHex: "#E3E3E3")!.cgColor
    }
    
    private func closeWindow() {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    @IBAction func onCloseImage(_ sender: Any) {
        delegate?.closeShareResult(files: files)
    }

}
