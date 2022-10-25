//
//  NXHomeProtectResultView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeProtectResultViewDelegate: NSObjectProtocol {
    func onShare(files: [NXNXLFile], right: NXRightObligation)
    func closeProtectResult(files: [NXNXLFile])
}

extension NXHomeProtectResultViewDelegate {
    func onShare(files: [NXNXLFile], right: NXRightObligation){
        
    }
}

class NXHomeProtectResultView: NSView {

    
    @IBOutlet weak var heightForView: NSLayoutConstraint!
    @IBOutlet var nameTextView: NSTextView!
    @IBOutlet weak var middleView: NSView!
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet weak var destPathLabel: NSTextField!
    @IBOutlet weak var definedTypeLab: NSTextField!
    @IBOutlet weak var descLab: NSTextField!
    @IBOutlet weak var policyRightView: NSView!
    var    destinationString: String?
    var selectedFile: [NXNXLFile]! {
        didSet {
                var displayName = self.selectedFile.reduce("", { (str1, file) -> String in
                    return str1 + "\n" + file.name
                })
                displayName.removeFirst()
                
                self.nameTextView.string = displayName
                
                if self.selectedFile.count > 1 {
                    self.titleLbl.stringValue = "Create protected files"
                }
                if (self.destPathStr != nil){
                    self.destPathLabel.stringValue = self.destPathStr!
                }
        }
    }
    var right: NXRightObligation? {
        didSet {
                self.rightView = NXCommonUtils.createViewFromXib(xibName: "NXRightViewOnly", identifier: "rightViewOnly", frame: nil, superView: self.policyRightView) as? NXRightViewOnly
            if tags?.count ?? 0 > 0 {
                  self.rightView?.ItemCountMax = 6
            }
            self.rightView?.right = self.right
            
        }
    }
    
    var tags: [String: [String]]? {
        didSet {
            self.middleView.wantsLayer = true
            self.middleView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
            self.destPathLabel.stringValue = self.destPathStr ?? ""
            self.definedTypeLab.stringValue = "Permissions applied to the file"
          //  self.descLab.stringValue = "Company-defined rights are permissions determined by centralized policies"
            self.protectTagsResultView = NXCommonUtils.createViewFromXib(xibName: "NXResultTagsView", identifier: "NXResultTagsView", frame: nil, superView: self.middleView) as? NXResultTagsView
            self.protectTagsResultView?.tags = tags!
        }
    }
    var destPathStr: String?
    weak var delegate: NXHomeProtectResultViewDelegate?
    private var rightView: NXRightViewOnly?
    private var protectTagsResultView: NXResultTagsView?
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if self.tags == nil {
            self.heightForView.constant = 1
        } else {
            self.heightForView.constant = 80
        }
        guard let _ = superview else {
            return
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.init(colorWithHex: "#E3E3E3")?.cgColor
        
        nameTextView.textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0)
    }
    
    @IBAction func onCloseImage(_ sender: Any) {
        closeWindow()
    }
    @IBAction func onCloseBtn(_ sender: Any) {
        closeWindow()
    }

    func closeWindow() {
        delegate?.closeProtectResult(files: self.selectedFile)
    }
}

extension NXHomeProtectResultView: NXMouseEventTextFieldDelegate {
    func mouseDownTextField(sender: Any, event: NSEvent) {
        delegate?.onShare(files: self.selectedFile, right: self.right!)
    }
}

