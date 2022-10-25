//
//  NXNewProjectVC.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/3.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXNewProjectVC: NSViewController{

    weak var delegate: NXNewProjectDelegate?
    
    
    @IBOutlet weak var emailError: NSTextField!
    @IBOutlet weak var projectNameError: NSTextField!
    @IBOutlet weak var descriptionError: NSTextField!
    
    @IBOutlet weak var createBtn: NSButton!
    private var emailView: NXEmailView!
    private var commentView: NXCommentsView!
    
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var nameContainerView: NSView!
    @IBOutlet weak var descriptionContainerView: NSView!
    
    fileprivate var nameView: NXCommentsView!
    fileprivate var descriptionView: NXCommentsView!
    
    fileprivate var waitView:NXWaitingView!
    
    fileprivate var isNameLegal = false
    fileprivate var isDescriptionLegal = false
    
    fileprivate struct Constant {
        static let maxNameLength = 50
        static let maxDescriptionLength = 250
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame: nil, superView: contentView) as? NXEmailView
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView.placeholder = NSLocalizedString("COMMENT_VIEW_INIVITATION_MSG", comment: "")
        
        nameView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: nameContainerView) as? NXCommentsView
        nameView.placeholder = NSLocalizedString("NEW_PROJECT_NAME_PLACEHOLDER", comment: "")
        nameView.maxcount = 50
        nameView.delegate = self
        
        descriptionView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: descriptionContainerView) as? NXCommentsView
        descriptionView.placeholder = NSLocalizedString("NEW_PROJECT_DESCRIPTION_PLACEHOLDER", comment: "")
        descriptionView.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        createBtn.wantsLayer = true
        createBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        createBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: createBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, createBtn.title.count))
        createBtn.attributedTitle = titleAttr
        
        waitView = NXCommonUtils.createWaitingView(superView: self.view)
        waitView.isHidden = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true;
        self.view.window?.styleMask = .titled
        self.view.window?.backgroundColor = NSColor.white
    }
    
    override func viewWillDisappear() {
        clearView()
    }
    
    func onCreateFinish(){
        waitView.removeFromSuperview()
        self.presentingViewController?.dismiss(self)
    }
    
    @IBAction func onCreate(_ sender: Any) {
        emailError.isHidden = true
        
        emailView.currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
        guard delegate != nil else{
            return
        }
        
        let newTitleLabel = nameView.comments.trimmingCharacters(in: .whitespaces)
        if newTitleLabel == "" {
            NXCommonUtils.showWarningLabel(label: projectNameError, str: NSLocalizedString("PROJECT_CREATE_VC_WARNING_TITLE", comment: ""))
            self.view.window?.makeFirstResponder(nameView)
            return
        }
        
        let newDescriptionLabel = descriptionView.comments.trimmingCharacters(in: .whitespaces)
        if newDescriptionLabel == "" {
            NXCommonUtils.showWarningLabel(label: descriptionError, str: NSLocalizedString("PROJECT_CREATE_VC_WARNING_DESCRIPTION", comment: ""))
            self.view.window?.makeFirstResponder(descriptionView)
            return
        }
        
        if isNameLegal != true || isDescriptionLegal != true{
            return
        }
        for item in self.emailView.emailsArray {
            if emailView.isValidate(email: item) == false {
                NXCommonUtils.showWarningLabel(label: emailError, str: NSLocalizedString("PROJECT_NEW_VC_INVALID_EMAIL", comment: ""))
                self.view.window?.makeFirstResponder(emailView)
                return
            }
        }
        
        waitView.isHidden = false
        delegate?.onNewProject(title: newTitleLabel, description: newDescriptionLabel, emailArray: emailView.emailsArray, invitationMsg: commentView.comments)
    }
    @IBAction func onCloseImage(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
    
    func isNameStandard(value: String)->Int{
        guard !value.isEmpty else {
            return 3
        }
        
        guard value.count <= Constant.maxNameLength else {
            return 1
        }
        
        let range = value.range(of: "\n")
        if range != nil {
            return 4
        }
        
        let isStandardValue: Int = {
            let specialCharacters = "^[\\u00C0-\\u1FFF\\u2C00-\\uD7FF\\w \\x22\\x23\\x27\\x2C\\x2D]+$"//"[\\w\"\\s',-_#]*?"
            let predicate = NSPredicate(format: "SELF MATCHES %@", specialCharacters)
            if predicate.evaluate(with: value){
                return 0
            }else{
                return 2
            }
        }()
        
        return isStandardValue
    }
    
    func isDescriptionStandard(value: String)->Int{
        guard !value.isEmpty else {
            return 3
        }
        
        guard value.count <= Constant.maxDescriptionLength else {
            return 1
        }
    
        return 0
    }
    
    fileprivate func clearView(){
        self.projectNameError.isHidden = true
        self.descriptionError.isHidden = true
        self.emailError.isHidden = true
        
        self.nameView.comments = ""
        self.descriptionView.comments = ""
        
        self.emailView.clear()
    }
}

extension NXNewProjectVC: NXCommentsViewDelegate {
    func textDidChange(with view: NXCommentsView) {
        if view == nameView {
            //0: normal, 1: length, 2: specific characher, 3: empty, 4: include '\n'
            let isStandardValue = isNameStandard(value: view.comments)
            if isStandardValue == 1 {
                self.projectNameError.stringValue = NSLocalizedString("PROJECT_CREATE_VC_TITLE_LENGTH_ERROR", comment: "")
                self.projectNameError.isHidden = false
                isNameLegal = false
            }else if isStandardValue == 2{
                self.projectNameError.stringValue = NSLocalizedString("PROJECT_CREATE_VC_TITLE_SPECIFIC_ERROR", comment: "")
                self.projectNameError.isHidden = false
                isNameLegal = false
            }else if isStandardValue == 3 || isStandardValue == 0 {
                self.projectNameError.isHidden = true
                isNameLegal = true
            } else if isStandardValue == 4 {
                // current input '\n', just remove it and do nothing
                let name = view.comments.replacingOccurrences(of: "\n", with: "")
                view.comments = name
            }
        } else if view == descriptionView {
            let isStandardValue = isDescriptionStandard(value: view.comments)
            if isStandardValue == 1 {
                self.descriptionError.stringValue = NSLocalizedString("PROJECT_CREATE_VC_DESCRIPTION_LENGTH_ERROR", comment: "")
                self.descriptionError.isHidden = false
                isDescriptionLegal = false
            }else{
                self.descriptionError.isHidden = true
                isDescriptionLegal = true
            }
        }
    }
}
