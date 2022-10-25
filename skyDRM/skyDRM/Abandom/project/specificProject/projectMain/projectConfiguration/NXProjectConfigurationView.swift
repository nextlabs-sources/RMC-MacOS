//
//  NXProjectConfigurationView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 18/08/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectConfigurationView: NSView, NSTextFieldDelegate {

    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var nameTipLabel: NSTextField!
    @IBOutlet weak var descriptionTipLabel: NSTextField!
    
    @IBOutlet weak var nameContainer: NSView!
    @IBOutlet weak var descriptionContainer: NSView!
    
    fileprivate enum TitleError {
        case success
        case length
        case specificCharacher
        case empty
        case sameAsOld
        case includeEnter
    }
    fileprivate enum DescriptionError {
        case success
        case length
        case empty
        case sameAsOld
    }
    fileprivate enum CommentError {
        case success
        case sameAsOld
    }
    fileprivate struct Constant {
        static let maxNameLength = 50
        static let maxDescriptionLength = 250
    }
    fileprivate var commentView: NXCommentsView!
    fileprivate var nameView: NXCommentsView!
    fileprivate var descriptionView: NXCommentsView!
    
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var isNameValid = false
    fileprivate var isDescriptionValid = false
    fileprivate var isCommentValid = false
    fileprivate var isEnabled = false
    
    fileprivate var waitView: NXWaitingView!
    private var infoConext = 0
    fileprivate var projectInfo = NXProject() {
        didSet {
            DispatchQueue.main.async {
                //update UI
                if let name = self.projectInfo.name {
                    self.nameView.comments = name
                }
                if let projectDescription = self.projectInfo.projectDescription {
                    self.descriptionView.comments = projectDescription
                }
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        saveBtn.wantsLayer = true
        saveBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        saveBtn.layer?.cornerRadius = 5
        updateButtonStatus()
        
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView.placeholder = NSLocalizedString("COMMENT_VIEW_INIVITATION_MSG", comment: "")
        commentView.delegate = self
        waitView = NXCommonUtils.createWaitingView(superView: self)
        waitView.isHidden = true
        
        nameView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: nameContainer) as? NXCommentsView
        nameView.maxcount = 50
        nameView.delegate = self
        
        descriptionView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: descriptionContainer) as? NXCommentsView
        descriptionView.delegate = self
        
        nameTipLabel.isHidden = true
        descriptionTipLabel.isHidden = true
        
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        self.projectInfo = NXSpecificProjectData.shared.getProjectInfo().copy() as! NXProject
        //get project meta data
        self.waitView.isHidden = false
        self.projectService?.getProjectMetadata(project: self.projectInfo)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            let gProjectInfo = NXSpecificProjectData.shared.getProjectInfo()
            self.projectInfo = gProjectInfo.copy() as! NXProject
            
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    @IBAction func onUpdate(_ sender: Any) {
        if !isEnabled {
            return
        }
        waitView.isHidden = false
        let toUpdate = projectInfo.copy() as! NXProject
        toUpdate.name = nameView.comments.trimmingCharacters(in: .whitespaces)
        toUpdate.projectDescription = descriptionView.comments.trimmingCharacters(in: .whitespaces)
        toUpdate.invitationMsg = commentView.comments
        projectService?.updateProject(project: toUpdate)
    }
    
    fileprivate func checkName(name: String) -> TitleError {
        if name == "" {
            isNameValid = false
            return .empty
        }
        else if name == projectInfo.name {
            isNameValid = false
            return .sameAsOld
        }
        else if name.count > Constant.maxNameLength {
            isNameValid = false
            return .length
        }
        
        let range = name.range(of: "\n")
        if range != nil {
            return .includeEnter
        }
        
        let specialCharacters = "^[\\u00C0-\\u1FFF\\u2C00-\\uD7FF\\w \\x22\\x23\\x27\\x2C\\x2D]+$"//"[\\w\"\\s',-_#]*?"
        let predicate = NSPredicate(format: "SELF MATCHES %@", specialCharacters)
        if !predicate.evaluate(with: name) {
            isNameValid = false
            return .specificCharacher
        }
        
        isNameValid = true
        return .success
    }
    
    fileprivate func showNameTip(error: TitleError) {
        switch error {
        case .empty:
            NXCommonUtils.showWarningLabel(label: nameTipLabel, str: NSLocalizedString("PROJECT_CREATE_VC_WARNING_TITLE", comment: ""))
        case .length:
            NXCommonUtils.showWarningLabel(label: nameTipLabel, str: NSLocalizedString("PROJECT_CREATE_VC_TITLE_LENGTH_ERROR", comment: ""))
        case .specificCharacher:
            NXCommonUtils.showWarningLabel(label: nameTipLabel, str: NSLocalizedString("PROJECT_CREATE_VC_TITLE_SPECIFIC_ERROR", comment: ""))
        case .success, .sameAsOld:
            nameTipLabel.isHidden = true
        case .includeEnter:
            break
        }
    }
    
    fileprivate func checkDescription(description: String) -> DescriptionError {
        if description == "" {
            isDescriptionValid = false
            return .empty
        }
        else if description == projectInfo.projectDescription {
            isDescriptionValid = false
            return .sameAsOld
        }
        else if description.count > Constant.maxDescriptionLength {
            isDescriptionValid = false
            return .length
        }
        isDescriptionValid = true
        return .success
    }
    
    fileprivate func showDescriptionTip(error: DescriptionError) {
        switch error {
        case .empty:
            NXCommonUtils.showWarningLabel(label: descriptionTipLabel, str: NSLocalizedString("PROJECT_CREATE_VC_WARNING_DESCRIPTION", comment: ""))
        case .length:
            NXCommonUtils.showWarningLabel(label: descriptionTipLabel, str: NSLocalizedString("PROJECT_CREATE_VC_DESCRIPTION_LENGTH_ERROR", comment: ""))
        case .sameAsOld, .success:
            descriptionTipLabel.isHidden = true
        }
    }
    
    fileprivate func updateButtonStatus() {
        let titleAttr = NSMutableAttributedString(attributedString: saveBtn.attributedTitle)
        if isEnabled {
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, saveBtn.title.count))
        } else {
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#E6E6E6", alpha: 1.0)!], range: NSMakeRange(0, saveBtn.title.count))
        }
        saveBtn.attributedTitle = titleAttr
    }
}

extension NXProjectConfigurationView: NXProjectAdapterDelegate {
    func updateProjectFinish(project: NXProject, error: Error?) {
        waitView.isHidden = true
        if let _ = error {
            
            DispatchQueue.main.async{
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("UPDATE_PROJECT_FAILED", comment: ""))
            }
        }
        else {
            projectInfo = project
            NXSpecificProjectData.shared.setProjectInfo(info: project.copy() as! NXProject)
            DispatchQueue.main.async{
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("UPDATE_PROJECT_SUCCESS", comment: ""))
            }
            isEnabled = false
            updateButtonStatus()
        }
    }
    func getProjectMetadataFinish(projectId: String, project: NXProject?, error: Error?) {
        waitView.isHidden = true
        if let _ = error {
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("GET_PROJECT_META_DATA_FAILED", comment: ""))
            }
        }
        
        if let invitation = project?.invitationMsg {
            self.commentView.comments = invitation
            self.projectInfo.invitationMsg = invitation
        }
    }
}

extension NXProjectConfigurationView: NXCommentsViewDelegate {
    func textDidChange(with view: NXCommentsView) {
        if view == nameView {
            let error = checkName(name: view.comments)
            showNameTip(error: error)
            
            // current input '\n', just remove it and do nothing
            if error == .includeEnter {
                let name = view.comments.replacingOccurrences(of: "\n", with: "")
                view.comments = name
                return
            }
            
            isEnabled = (error == .success) || isDescriptionValid || isCommentValid
            updateButtonStatus()
        } else if view == descriptionView {
            let error = checkDescription(description: view.comments)
            showDescriptionTip(error: error)
            isEnabled = error == .success || isNameValid && isCommentValid
            updateButtonStatus()
        } else if view == commentView {
            let error = checkComment(comment: commentView.comments)
            isEnabled = error == .success || isNameValid || isDescriptionValid
            updateButtonStatus()
        }
        
    }
    
    private func checkComment(comment: String) -> CommentError {
        if comment == projectInfo.invitationMsg {
            isCommentValid = false
            return .sameAsOld
        }
        isCommentValid = true
        return .success
    }
}
