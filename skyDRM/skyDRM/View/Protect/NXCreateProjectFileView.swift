//
//  AddFileToProjectViewController.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2019/5/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa
import SDML
protocol NXCreateProjectFileViewDelegate: class {
    func protectFinish(files:[NXNXLFile],right:NXRightObligation, tags:[String:[String]], destPath:String, type:NXProtectType)
    func dealWithProtectFailed()
    func backAction()
}
class NXCreateProjectFileView: NXProgressIndicatorView {
    var destinationString:String = ""
    var protectType:NXProtectType = .project
    var projectModel:NXProjectModel?
    var syncFile:NXSyncFile?
    var  changeFileBlock:ChangeBlock?
    weak var delegate:NXCreateProjectFileViewDelegate?
    private var policyTagsView: NXResultTagsView?
    fileprivate var rightsViewController: PolicyRightsViewController? = nil
    private var policyRightView: NXRightViewOnly?
    fileprivate  struct Constant {
      static let rightsViewControllerXibName = "NXPolicyRightsViewController"
    }
    
    @IBOutlet var fileTextView: NSTextView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var selectFileLib: NSTextField!
    @IBOutlet weak var changeDistinationButton: NXTrackingButton!
    @IBOutlet weak var discription: NSTextField!
    @IBOutlet weak var tipsLabel: NSTextField!
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var tagsView: NSView!
    @IBOutlet weak var rightView: NSView!
    @IBOutlet weak var addFileButton: NSButton!
    var paths=[String]() 
    var selectedFile:[NXSelectedFile]! {
        willSet {
            paths = newValue.map{$0.url!.path}
            let urls = newValue.map{$0.url!}
            if self.checkFiles(urls:urls) {
                    var str = ""
                    for url in urls {
                        str += url.path + "\n"
                    }
                    str.removeLast()
                    str.removeLast()
                    if urls.count > 1 {
                    let str = String(format: "Selected file (%i)", urls.count)
                        self.selectFileLib.stringValue = str
                        self.titleLabel.stringValue = "Create protected files"
                    } else {
                        self.selectFileLib.stringValue = "Selected file"
                        self.titleLabel.stringValue = "Create a protected file"
                    }
                    
                    self.fileTextView.string = str
                    self.fileTextView.setTextColor(NSColor(colorWithHex: "#828282"), range: NSMakeRange(0, str.count))
                    self.fileTextView.font = NSFont.systemFont(ofSize: 10)
            }
        }
    }
    var tags: [String: [String]] = [:] {
      didSet {
            self.tagsView.wantsLayer = true
            self.tagsView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
            self.policyTagsView = NXCommonUtils.createViewFromXib(xibName: "NXResultTagsView", identifier: "NXResultTagsView", frame:self.tagsView.bounds, superView: self.tagsView) as? NXResultTagsView
            self.policyTagsView?.tags = tags
        
            if protectType == .local {
                self.projectNameLabel.stringValue = ""
                self.tipsLabel.stringValue = "Permissions granted for this file"
            } else {
                if let projectFile = syncFile?.file.sdmlBaseFile as? SDMLProjectFile {
                    self.projectNameLabel.stringValue = projectFile.getProject().getName()
                } else if let project = projectModel?.sdmlProject {
                    self.projectNameLabel.stringValue = project.getName()
                } else {
                    self.projectNameLabel.stringValue = ""
                }
            }
        }
    }
    var right:NXRightObligation? {
         didSet {
                self.policyRightView = NXCommonUtils.createViewFromXib(xibName: "NXRightViewOnly", identifier: "rightViewOnly", frame: self.rightView.bounds, superView: self.rightView) as? NXRightViewOnly
                self.policyRightView?.ItemCountMax = 6
                self.policyRightView?.right = self.right
                self.policyRightView?.frame = self.rightView.bounds
                self.policyRightView?.watermarkTag.isHidden = true
                self.policyRightView?.validityLab.isHidden = true
                self.policyRightView?.watermarkLabel.isHidden = true
                self.policyRightView?.validityLab.isHidden = true
            
        }
    }
    
    func addMaskView() {
        if let parentView = NSApplication.shared.keyWindow?.contentView {
            parentView.addSubview(MaskView.sharedInstance)
        }
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
    }
    
    func removeMaskView() {
        MaskView.sharedInstance.removeFromSuperview()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let _ = superview else {
            return
        }
        projectNameLabel.textColor = NSColor(red: 10.0 / 255, green: 128.0 / 255, blue: 255.0 / 255, alpha: 1)
        self.window?.delegate = self
        addFileButton.wantsLayer = true
        addFileButton.layer?.backgroundColor = GREEN_COLOR.cgColor
        addFileButton.layer?.cornerRadius = 5
        let muAtti = NSMutableAttributedString(attributedString:changeDistinationButton.attributedTitle)
        muAtti.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber(value: NSUnderlineStyle.single.rawValue), range: NSMakeRange(0, changeDistinationButton.title.count))
        changeDistinationButton.attributedTitle = muAtti
        
        let startColor = NSColor(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: addFileButton.bounds, start: startColor, end: endColor)
        addFileButton.layer?.addSublayer(gradientLayer)
        let titleAttr = NSMutableAttributedString(attributedString: addFileButton.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor:NSColor.white], range: NSMakeRange(0, addFileButton.title.count))
        addFileButton.attributedTitle = titleAttr
        fileTextView.isEditable = false
    }
    

    private func checkFiles(urls:[URL]) -> Bool {
        var result = true
        startAnimation()
        for url in urls {
            let isNXL = NXClient.isNXLFile(path: url.path)
            if isNXL {
                result = false
                break
            }
        }
        
        if  result == false {
            let message = NSLocalizedString("FILE_OPERATION_PROTECT_FAILED", comment: "")
            NSAlert.showAlert(withMessage: message, informativeText: "") { (_) in
                self.delegate?.dealWithProtectFailed()
            }
        }
        stopAnimation()
        return result
    }
    
    @IBAction func changeDistination(_ sender: NSButton) {
        let action:([URL]) -> Void = { urls in
            self.selectedFile = urls.map() {.localFile(url:$0)}
            weak var weakSelf = self
            if self.changeFileBlock != nil {
                self.changeFileBlock!(weakSelf?.selectedFile ?? [])
            }
        }
        if let window = self.window {
            NXCommonUtils.openPanel(parentWindow: window, allowMultiSelect: true, completion: action)
        }
    }

    // TODO: to back the view
    @IBAction func backAction(_ sender: NSButton) {
        delegate?.backAction()
    }

    //TODO: to implement the method to add nxl file to the project

    @IBAction func addFileAction(_ sender: NSButton) {
        self.startAnimation()
        self.protectFile(paths: paths, tags: tags, right: right) { (files) in
            self.stopAnimation()
            if files.count < self.paths.count {
                let successedCount = files.count
                let failedCount = self.paths.count - files.count
                NXToastWindow.sharedInstance?.toast("\(successedCount) success,\(failedCount)failed")
            }
            if files.count > 0 {
                self.delegate?.protectFinish(files: files, right: self.right!, tags: self.tags, destPath: self.destinationString, type: self.protectType)
            
            } else {
                self.delegate?.dealWithProtectFailed()
            }
        }
    }

    @IBAction func cancelAction(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
        }
}
extension NXCreateProjectFileView {
    fileprivate func protectFile(paths:[String],tags:[String:[String]],right:NXRightObligation? = nil,completion:@escaping([NXNXLFile]) -> ()) {
        var result  = [NXNXLFile]()
        result.reserveCapacity(paths.count)
        let group = DispatchGroup()
        let names = paths.map { path -> String in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return name
            }.filter { (name) -> Bool in
                return name.contains(":") || name.contains("*") || name.contains("?") || name.contains("<") || name.contains("|") || name.contains(">")
        }
        if names.count > 0 {
            self.stopAnimation()
            NSAlert.showAlert(withMessage: #"We don't support to protect a file, which the file name contains any of the following characters: \ / : * ? < > |"#)
            return
        }
        
        for path in paths {
            group.enter()
            if self.protectType == .local {
                NXClient.getCurrentClient().protectFileToLocal(path: path, right: nil, tags: tags, destPath:destinationString) { (file, error) in
                    if let file = file {
                        let nxFile = NXSyncFile(file: file as NXFileBase)
                        let status = NXSyncFileStatus()
                        status.status = .completed
                        nxFile.syncStatus = status
                        NotificationCenter.default.post(name: NXNotification.trayViewUpdated.notificationName,object: file)
                        NotificationCenter.post(notification: NXNotification.systembucketProtectSuccess, object: nxFile)

                        result.append(file)
                    } else {
                        debugPrint(error as Any)
                    }
                    group.leave()
                }
            } else {
                var parentFile: SDMLNXLFile?
                if protectType == .project {
                    parentFile = ((protectType == .project ? (projectModel != nil ? projectModel?.sdmlProject?.getFileManager().getRootFolder() : syncFile?.file.sdmlBaseFile as? SDMLProjectFile):nil)!)
                } else if protectType == .workspace {
                    parentFile = syncFile?.file.sdmlBaseFile as? SDMLNXLFile
                }
                
                NXClient.getCurrentClient().protectFile(type: protectType, path: path, right: right, tags: tags, parentFile: parentFile) { (file, error) in
                    if let file = file {
                        let nxFile = NXSyncFile(file: file as NXFileBase)
                        let status = NXSyncFileStatus()
                        status.status = .waiting
                        nxFile.syncStatus = status
                     NotificationCenter.post(notification: NXNotification.waitingUpload, object: nxFile)
                        
                        if self.protectType == .project {
                            NotificationCenter.default.post(name: NXNotification.projectProtected.notificationName, object: file)
                        } else if self.protectType == .workspace {
                            NotificationCenter.default.post(name: NXNotification.workspaceProtected.notificationName, object: file)
                        }
                        result.append(file)
                    } else {
                        debugPrint(error as Any)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            let nxlFile  = result.map{$0 as NXFileBase}
            let syncFile = nxlFile.map{NXSyncFile(file: $0)}
            let status = NXSyncFileStatus()
                status.status = .waiting
                _ = syncFile.map{$0.syncStatus = status}
             for nxSyncFile in syncFile {
                NotificationCenter.post(notification: NXNotification.waitingUpload, object: nxSyncFile)
            }
            completion(result)
        }
    }
}
extension NXCreateProjectFileView:NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.cancelAction(self)
    }
}
