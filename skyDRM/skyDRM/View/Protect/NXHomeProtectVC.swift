//
//  NXHomeProtectVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/18.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

enum NXProtectType {
    case myVault
    case project
    case myVaultShared
    case local
    case workspace
}

protocol NXHomeProtectVCDelegate: NSObjectProtocol {
    func protectFinish(files: [NXNXLFile])
}

class NXHomeProtectVC: NSViewController {

    weak var delegate: NXHomeProtectVCDelegate?
    var   protectType: NXProtectType = .myVault
    var    destinationString: String = "MyVault"
    var        fileFromMacUser: Bool = false
    var      projectRoot: NXProjectRoot?
    var      tags:[String:[String]]?
    var     projectModel: NXProjectModel? {
        didSet{
            if projectModel != nil {
                destinationString = (projectModel?.name)! + "/"
            }
        }
    }
    var  syncFile: NXSyncFile? {
        didSet {
            if syncFile != nil {
                destinationString = NXCommonUtils.getDestinationString(file: syncFile!.file)
            }
        }
    }
    
    @IBOutlet weak var contentView: NSView!
//    fileprivate var protectMainView: NXHomeProtectMainView?
    fileprivate var protectConfigureView: NXHomeProtectConfigureView?
    fileprivate var protectResultView: NXHomeProtectResultView?
//    fileprivate var shareMainView: NXHomeShareMainView?
    fileprivate var createProtectFileView:NXCreateProjectFileView?
    fileprivate var changeFileDestinationView: NXChangeFileDestinationConfigureView?
    fileprivate var shareConfigureView: NXHomeShareConfigureView?
    fileprivate var shareConfigViewController: NSViewController?
    
    fileprivate var shareResultView: NXHomeShareResultView?
    public enum MainViewType {
        case selectFile
        case configure
        case result
        case shareConfigure
        case shareResult
        case tagsFile
    }
    public var mainViewType: MainViewType = .configure
    public var selectedFile: [NXSelectedFile]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        if protectType == .myVault {
            destinationString = "MyVault"
        } else if protectType == .workspace,
            syncFile == nil {
            destinationString = "Workspace"
        }
        
        if fileFromMacUser {
            showChangeDestinationView()
        } else {
            showProtectConfigureView()
        }
    }
    
    deinit {
        YMLog("homeProtectVC: i am die!!!")
    }
    
    private func adjustWindowPosition(with parentWindow: NSWindow?) {
        if let mainScreen = NSScreen.main,
            let window = view.window {
            let x = mainScreen.visibleFrame.origin.x + (mainScreen.visibleFrame.size.width - window.frame.size.width)/2
            let y = mainScreen.visibleFrame.origin.y + (mainScreen.visibleFrame.size.height + window.frame.size.height)/2
            let point = NSMakePoint(x, y)
            
            window.setFrameTopLeftPoint(point)
        }
    }
    
//    fileprivate func showProtectMainView() {
//        removeAllView()
//        protectMainView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectMainView", identifier: "homeProtectMainView", frame: nil, superView: contentView) as? NXHomeProtectMainView
//        protectMainView?.delegate = self
//    }
    fileprivate func showProtectConfigureView() {
        removeAllView()
        protectConfigureView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectConfigureView", identifier: "homeProtectConfigureView", frame: nil, superView: contentView) as? NXHomeProtectConfigureView
        protectConfigureView?.delegate = self
        protectConfigureView?.destinationString = destinationString
        protectConfigureView?.syncFile = syncFile
        if protectType == .project {
            if projectModel != nil {
                protectConfigureView?.projectModel = projectModel
                guard  let tagTemplate = projectModel?.sdmlProject?.getProjectTags() else {
                    return 
                }
                let nxProjectTagTemplateModel = NXProjectTagTemplateModel()
                NXCommonUtils.transform(from: tagTemplate, to: nxProjectTagTemplateModel)
                protectConfigureView?.projectTagTemplateModel = nxProjectTagTemplateModel
            } else if let projectFile = syncFile?.file as? NXProjectFileModel {
                protectConfigureView?.syncFile = syncFile
                protectConfigureView?.projectTagTemplateModel = projectFile.project?.tagTemplate
            }
        } else if protectType == .local{
            protectConfigureView?.projectTagTemplateModel = NXClient.getCurrentClient().getSystemTagModel()
        } else if protectType == .workspace {
            protectConfigureView?.projectTagTemplateModel = NXClient.getCurrentClient().getSystemTagModel()
        }
        
        protectConfigureView?.protectType = protectType
        if let selectedFile = selectedFile {
            protectConfigureView?.selectedFile = selectedFile
        }
        weak var weakSelf = self
        protectConfigureView?.changeFileBlock = { (files) -> () in 
            weakSelf?.selectedFile = files
        }
        
        if let window = self.view.window {
            window.title = NXConstant.kTitle //"Protect a file"
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: ((self.protectType == .project || self.protectType == .local || self.protectType == .workspace) ? 550 : 490)))
        }
    }
    
    fileprivate func showCreateProjectFileView() {
        removeAllView()
        createProtectFileView = NXCommonUtils.createViewFromXib(xibName: "NXCreateProjectFileView", identifier: "nxCreateProjectFileView", frame: nil, superView: contentView) as? NXCreateProjectFileView
        createProtectFileView?.delegate = self
        createProtectFileView?.destinationString = destinationString
        createProtectFileView?.syncFile = syncFile
        createProtectFileView?.selectedFile = selectedFile
        if protectType == .project || protectType == .local {
            if projectModel != nil {
             createProtectFileView?.projectModel = projectModel
            if let selectedFile = selectedFile {
                    createProtectFileView?.selectedFile = selectedFile
                }
            }
        }
        weak var weakSelf = self
        createProtectFileView?.changeFileBlock = { (files) -> () in
            weakSelf?.selectedFile = files
        }
        
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: 550))
        }
    }
    
    
    fileprivate func showChangeDestinationView() {
        removeAllView()
        changeFileDestinationView = NXCommonUtils.createViewFromXib(xibName: "NXChangeFileDestinationConfigureView", identifier: "changeFileDestinationConfigureView", frame: nil, superView: self.contentView) as? NXChangeFileDestinationConfigureView
        changeFileDestinationView?.delegate = self
        changeFileDestinationView?.selectedFile = selectedFile
        if protectType == .project {
             changeFileDestinationView?.projectModel = projectModel
        }
       
        changeFileDestinationView?.syncFile    = syncFile
        changeFileDestinationView?.destinationString = destinationString
        changeFileDestinationView?.projectRootModel = projectRoot
        changeFileDestinationView?.protectType = protectType
//        if let window = self.view.window {
//            window.title = NXConstant.kTitle
//            window.styleMask.remove(.resizable)
//            window.delegate = self
//            window.setContentSize(NSSize(width: 650, height: 550))
//            
//        }
    }
    
    fileprivate func showProtectResultView() {
        removeAllView()
        protectResultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectResultView", identifier: "homeProtectResultView", frame: nil, superView: contentView) as? NXHomeProtectResultView
        protectResultView?.delegate = self
        protectResultView?.destPathStr = destinationString
    }
//    fileprivate func showShareMainView() {
//        removeAllView()
//        shareMainView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareMainView", identifier: "homeShareMainView", frame: nil, superView: contentView) as? NXHomeShareMainView
//        shareMainView?.delegate = self
//    }
    
    fileprivate func showShareConfigureView() {
        shareConfigureView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareConfigureView", identifier: "homeShareConfigureView", frame: contentView.frame, superView: nil) as? NXHomeShareConfigureView
        shareConfigureView?.delegate = self
        shareConfigViewController = NSViewController()
        shareConfigViewController?.view = shareConfigureView!
        shareConfigViewController?.title = NSLocalizedString("TITLE_SkyDRM_Desktop", comment: "")
        self.presentAsModalWindow(shareConfigViewController!)
    }
    
    fileprivate func showShareResultView() {
        shareResultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareResultView", identifier: "homeShareResultView", frame: nil, superView: shareConfigureView) as? NXHomeShareResultView
        shareResultView?.delegate = self
    }
    
   fileprivate func removeAllView() {
//        protectMainView?.removeFromSuperview()
        protectConfigureView?.removeFromSuperview()
        protectResultView?.removeFromSuperview()
//        shareMainView?.removeFromSuperview()
        shareConfigureView?.removeFromSuperview()
        shareResultView?.removeFromSuperview()
        changeFileDestinationView?.removeFromSuperview()
        createProtectFileView?.removeFromSuperview()
        
    }
    
    func close(files: [NXNXLFile]) {
        if protectType != .local {
            delegate?.protectFinish(files: files)
        }
        self.presentingViewController?.dismiss(self)
    }
}

//MARK: - NXHomeProtectMainViewDelegate
//extension NXHomeProtectVC: NXHomeProtectMainViewDelegate {
//    func onProtect(info: NXSelectedFile) {
//        DispatchQueue.main.async {
//            self.showProtectConfigureView()
//        }
//    }
//}

//MARK: - NXChangeFileDestinationConfigureViewDelegate
extension NXHomeProtectVC: NXChangeFileDestinationConfigureViewDelegate {
    func changeFileDestination(type: DestinationType, files: [NXSelectedFile], project: NXProjectModel?, syncFile: NXSyncFile?, destinationString: String?) {
        if type == .local {
            self.protectType       = .local
            self.destinationString = destinationString ?? ""
        } else if type == .centralMyVault {
            protectType            = .myVault
            self.destinationString = destinationString ?? ""
        }else if type == .project {
            protectType   = .project
            projectModel  = project
            self.syncFile = syncFile
        } else if type == .workspace {
            protectType = .workspace
            self.syncFile = syncFile
        }
        
        self.selectedFile = files
        showProtectConfigureView()
    }
    
    
}

//MARK: - NXHomeProtectConfigureViewDelegate
extension NXHomeProtectVC: NXHomeProtectConfigureViewDelegate {
    func nextCreateProjectFile(selectedFile: [NXSelectedFile], tags: [String : [String]], destPath: String, type: NXProtectType?,right:NXRightObligation) {
        protectType = type!
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: 550))
        }
        DispatchQueue.main.async {
            self.mainViewType = .tagsFile
            self.showCreateProjectFileView()
            self.createProtectFileView?.protectType = self.protectType
            self.createProtectFileView?.destinationString = destPath
            self.createProtectFileView?.tags = tags
            self.createProtectFileView?.projectModel = self.projectModel
            self.createProtectFileView?.selectedFile = selectedFile
            self.createProtectFileView?.right = right
        }
    }
    
    func changeDestinationAction(type: NXProtectType?) {
        showChangeDestinationView()
    }
    
    func nextCreateProtectedAndSharedNXLFile(selectedFile:[NXSelectedFile], right: NXRightObligation?, tags: [String: [String]]?,destPath: String?, type: NXProtectType?)
       {
        
    }
    func nextCreateProjectFile(paths:[String],tags: [String : [String]], destPath: String, type: NXProtectType?) {
        protectType = type!
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: 550))
        }
        
    }
    func protectFinish(files: [NXNXLFile], right: NXRightObligation?, tags: [String: [String]]?, destPath: String?, type: NXProtectType?) {
        protectType = type!
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: 550))
            
        }
        if right != nil {
            DispatchQueue.main.async {
                self.mainViewType = .result
                self.showProtectResultView()
                self.protectResultView?.selectedFile = files
                self.protectResultView?.right = right
            }
        }
    }
    
    
    func onProtectFailed() {
        close(files: [])
    }
    
}

//MARK: -  NXHomeProtectResultViewDelegate
extension NXHomeProtectVC: NXHomeProtectResultViewDelegate {
    func onShare(files: [NXNXLFile], right: NXRightObligation) {
        DispatchQueue.main.async {
            self.showShareConfigureView()
            self.shareConfigureView?.selectedFile = files
            self.shareConfigureView?.right = right
        }
    }
    
    func closeProtectResult(files: [NXNXLFile]) {
        close(files: files)
    }
}

//extension NXHomeProtectVC: NXHomeShareMainViewDelegate {
//    func onShare(info: NXSelectedFile) {
//    }
//}

extension NXHomeProtectVC: NXHomeShareConfigureViewDelegate {
    func onShareFinish(files: [NXNXLFile], right: NXRightObligation, emails: [String], comments: String) {
        DispatchQueue.main.async {
            self.mainViewType = .shareResult
            self.showShareResultView()
            self.shareResultView?.files = files
            self.shareResultView?.emails = emails
            self.shareResultView?.rights = right
            self.shareResultView?.comments = comments
        }
    }
    
    func onShareFailed() {
    }
    
    func onTapCancelShareButton()
    {
        if let shareConfigVC = self.shareConfigViewController {
            self.dismiss(shareConfigVC)
            self.shareConfigViewController = nil
        }
    }
    
    func closeShareConfigure(files: [NXNXLFile]) {
        if let shareConfigVC = self.shareConfigViewController {
            self.dismiss(shareConfigVC)
            self.shareConfigViewController = nil
        }
    }
}

extension NXHomeProtectVC: NXHomeShareResultViewDelegate {
    func closeShareResult(files: [NXNXLFile]) {
        if let shareConfigVC = self.shareConfigViewController {
            self.dismiss(shareConfigVC)
            self.shareConfigViewController = nil
        }
    }
}

//MARK: - NSWindowDelegate
extension NXHomeProtectVC: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        switch self.mainViewType {
        case .result:
            if let files = protectResultView?.selectedFile {
                close(files: files)
            }
        case .shareConfigure:
            if let files = shareConfigureView?.selectedFile {
                close(files: files)
            }
        case .shareResult:
            if let files = shareResultView?.files {
                close(files: files)
            }
        default:
            break
        }
    }
}
extension NXHomeProtectVC: NXCreateProjectFileViewDelegate {
    func protectFinish(files: [NXNXLFile], right: NXRightObligation, tags: [String : [String]], destPath: String, type: NXProtectType) {
        self.showProtectResultView()
            DispatchQueue.main.async {
                self.mainViewType = .result
                self.showProtectResultView()
                self.protectResultView?.selectedFile = files
                self.protectResultView?.destPathStr = destPath
                self.protectResultView?.tags = tags
                self.protectResultView?.right = right
                self.protectResultView?.heightForView.constant = 90
            }
    }
    func dealWithProtectFailed() {
        close(files: [])
    }
    func backAction() {
        self.removeAllView()
        self.showProtectConfigureView()
    }
}

