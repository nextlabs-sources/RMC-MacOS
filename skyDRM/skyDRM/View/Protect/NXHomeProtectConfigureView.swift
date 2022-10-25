//
//  NXHomeProtectConfigureView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXHomeProtectConfigureViewDelegate: NSObjectProtocol {
//    func onUploadFinish(info: NXSelectedFile, displayName: String, rights: [NXRightType], watermark: String, validity: String)
//  tags destPath
    func nextCreateProjectFile(selectedFile:[NXSelectedFile],tags:[String:[String]],destPath:String,type:NXProtectType?,right:NXRightObligation)
    func protectFinish(files: [NXNXLFile], right: NXRightObligation?, tags: [String: [String]]?, destPath: String?, type: NXProtectType?)
    func nextCreateProtectedAndSharedNXLFile(selectedFile:[NXSelectedFile], right: NXRightObligation?, tags: [String: [String]]?,destPath: String?, type: NXProtectType?)
    func onProtectFailed()
    func changeDestinationAction(type: NXProtectType?)
}

extension NXHomeProtectConfigureViewDelegate {
    func changeDestinationAction(type: NXProtectType?) {
    }
}

typealias ChangeBlock = (_ files: [NXSelectedFile]) -> ()

class NXHomeProtectConfigureView: NXProgressIndicatorView {

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var selectFileLbl: NSTextField!
    @IBOutlet var fileTextView: NSTextView!
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var changeBtn: NXTrackingButton!
    @IBOutlet weak var changeDestinationBtn: NXTrackingButton!
    @IBOutlet weak var destinationNameLabel: NSTextField!
    @IBOutlet weak var definedName: NSTextField!
    @IBOutlet weak var companyDefinedBtn: NSButton!
    @IBOutlet weak var userDefinedBtn: NSButton!
    @IBOutlet weak var contentViewTopConstraint: NSLayoutConstraint!
    
    var changeFileBlock: ChangeBlock?
    
    var selectedFile: [NXSelectedFile]! {
        willSet {
            let urls = newValue.map() { $0.url! }
            if checkFiles(urls: urls) {
                DispatchQueue.main.async {
                    var str = ""
                    for url in urls {
                        str += url.path + "\n"
                    }
                    // Remove last separator.
                    str.removeLast()
    
                    if urls.count > 1 {
                        let str = String(format: "Selected files (%i)", urls.count)
                        self.selectFileLbl.stringValue = str
                        if self.protectType == .myVaultShared {
                            self.titleLbl.stringValue = "Share protected files"
                        } else {
                            self.titleLbl.stringValue = "Create protected files"
                        }
                    } else {
                        self.selectFileLbl.stringValue = "Selected file"
                        if self.protectType == .myVaultShared {
                            self.titleLbl.stringValue = "Share a protected file"
                        } else {
                            self.titleLbl.stringValue = "Create a protected file"
                        }
                    }
                    
                    self.fileTextView.string = str
                    self.fileTextView.setTextColor(NSColor.init(colorWithHex: "#828282"), range: NSMakeRange(0, str.count) )
                    self.fileTextView.font = NSFont.systemFont(ofSize: 10)
                }
            }
            
        }
    }
    
    var     protectingFileCount: Int = 0
    var                protectedFile = [NXNXLFile]()
    var    destinationString: String = ""
    var               projectModel: NXProjectModel?
    var                   syncFile: NXSyncFile?
    var    projectTagTemplateModel: NXProjectTagTemplateModel?
    private var serialQueue = DispatchQueue(label: "com.skydrm.serial")
    
    fileprivate var rightsView: NXRightsView?
    fileprivate var tagTemplateView: NXProjectTagTemplateView?
    fileprivate var localFileSize: Int64 = 0
    fileprivate var repositoryfile = NXFileBase()
    weak var delegate: NXHomeProtectConfigureViewDelegate?
    fileprivate var downloadOrUploadId: Int? = nil
    fileprivate var bClosed = false
    
    var   protectType: NXProtectType = .myVault {
        didSet {
            var canSelect = false
            if protectType == .project || protectType == .local || protectType == .workspace,
                NXClient.getCurrentClient().getTenantPreference()?.getEnableADHoc() != false {
                canSelect = true
            }
            
            if canSelect {
                contentViewTopConstraint.constant = 85
                definedName.isHidden = false
                companyDefinedBtn.isHidden = false
                userDefinedBtn.isHidden = false
                companyDefinedBtn.state = NSControl.StateValue.on
                userDefinedBtn.state = NSControl.StateValue.off
            } else {
                contentViewTopConstraint.constant = 18
                definedName.isHidden = true
                companyDefinedBtn.isHidden = true
                userDefinedBtn.isHidden = true
                // Fix Bug 67914: Set disable User-defined Rights, unable to protect a control policy file to project
                companyDefinedBtn.state = NSControl.StateValue.on
                userDefinedBtn.state = NSControl.StateValue.off
            }
            
            if protectType == .myVaultShared {
                destinationNameLabel.stringValue = "MyVault"
                changeDestinationBtn.isHidden = true
            }else {
                
                let displayName: String
                if protectType == .myVault {
                    displayName = "MyVault"
                } else {
                    displayName = destinationString
                }
                destinationNameLabel.stringValue = displayName
                changeDestinationBtn.isHidden = false
                let destinationdMuAtti = NSMutableAttributedString(attributedString: changeDestinationBtn.attributedTitle)
                destinationdMuAtti.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: NSMakeRange(0, changeDestinationBtn.title.count))
                changeDestinationBtn.attributedTitle = destinationdMuAtti

            }
            if companyDefinedBtn.state == NSControl.StateValue.on {
                protectBtn.title = "Next"
            } else if userDefinedBtn.state == NSControl.StateValue.on {
                protectBtn.title = "Protect"
            }
            self.changeDefinedWithType(type: protectType)
            
        }
    }
    
    func changeDefinedWithType(type: NXProtectType) {
        
        if (type == .project || type == .local || type == .workspace) {
            if rightsView != nil {
                rightsView?.isHidden = true
            }
            if tagTemplateView == nil {
                tagTemplateView = NXCommonUtils.createViewFromXib(xibName: "NXProjectTagTemplateView", identifier: "TagTemplateView", frame: nil, superView: contentView) as? NXProjectTagTemplateView
                tagTemplateView?.tagModel = projectTagTemplateModel
            }else {
                tagTemplateView?.isHidden = false
            }
        }else {
            if tagTemplateView != nil {
                tagTemplateView?.isHidden = true
            }
            if rightsView == nil {
                rightsView = NXCommonUtils.createViewFromXib(xibName: "NXRightsView", identifier: "rightsView", frame: nil, superView: contentView) as? NXRightsView
                
                // Init watermark and expiry from preference.
                var watermark: NXFileWatermark?
                var expiry: NXFileExpiry?
                if protectType == .project {
                    // If in root folder, get project from projectModel, else from syncFile.
                    let project = projectModel ?? (syncFile?.file as? NXProjectFileModel)?.project
                    // If in root folder.
                    if let text = project?.sdmlProject?.getPreferenceWatermark().getText() {
                        watermark = NXFileWatermark(text: text)
                    }
                    if let preferenceExpiry = project?.sdmlProject?.getPreferenceExpiry() {
                        expiry = NXCommonUtils.transform(from: preferenceExpiry)
                    }
                    
                    
                } else {
                    if let text = NXClient.getCurrentClient().getUserPreference()?.getDefaultWatermark().getText() {
                        watermark = NXFileWatermark(text: text)
                    }
                    if let preferenceExpiry = NXClient.getCurrentClient().getUserPreference()?.getDefaultExpiry() {
                        expiry = NXCommonUtils.transform(from: preferenceExpiry)
                    }
                    
                }
                rightsView?.set(watermark: watermark, expiry: expiry)
            
            }else{
                rightsView?.isHidden = false
            }
            
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let outlineView = NSOutlineView()
        outlineView.rowHeight = 30
    
        // Drawing code here.
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
//        if downloadOrUploadId != nil {
//            DownloadUploadMgr.shared.cancel(id: downloadOrUploadId!)
//        }
        
        bClosed = true
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        
        self.window?.delegate = self
       
        destinationNameLabel.lineBreakMode = .byTruncatingTail
        // Custom buttons.
        protectBtn.wantsLayer = true
        protectBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        protectBtn.layer?.cornerRadius = 5
        let muAtti = NSMutableAttributedString(attributedString: changeBtn.attributedTitle)
        muAtti.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: NSMakeRange(0, changeBtn.title.count))
        changeBtn.attributedTitle = muAtti
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: protectBtn.bounds, start: startColor, end: endColor)
        protectBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: protectBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, protectBtn.title.count))
        protectBtn.attributedTitle = titleAttr
        
        
        fileTextView.isEditable = false
        
        self.changeBtn.attributedTitle = {
            let title = changeBtn.title
            let attriTitle = changeBtn.attributedTitle
            let attriString = NSMutableAttributedString(attributedString: attriTitle)
            attriString.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#0068DA")!], range: NSMakeRange(0, title.count))
            return attriString
        }()
        
        self.changeDestinationBtn.attributedTitle = {
            let title = changeDestinationBtn.title
            let attriTitle = changeDestinationBtn.attributedTitle
            let attriString = NSMutableAttributedString(attributedString: attriTitle)
            attriString.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#0168DA")!], range: NSMakeRange(0, title.count))
            return attriString
        }()
    }
    
    
    @IBAction func userDefinedAction(_ sender: Any) {
        companyDefinedBtn.state = NSControl.StateValue.off
        userDefinedBtn.state    = NSControl.StateValue.on
        protectBtn.title = "Protect"
        changeDefinedWithType(type: .myVault)
    }
    
    @IBAction func companyDefinedAction(_ sender: Any) {
        userDefinedBtn.state    = NSControl.StateValue.off
        companyDefinedBtn.state = NSControl.StateValue.on
        protectBtn.title = "Next"
        changeDefinedWithType(type: .project)
    }
    
    @IBAction func changeDestination(_ sender: Any) {
        if  delegate != nil {
            self.delegate?.changeDestinationAction(type: protectType)
        }
    }
    
    @IBAction func onChangeFile(_ sender: Any) {
        let action: ([URL]) -> Void = { urls in
            self.selectedFile = urls.map() { .localFile(url: $0) }
            weak var weakSelf = self
            if self.changeFileBlock != nil {
                self.changeFileBlock!(weakSelf?.selectedFile ?? [])
            }
        }
        
        if let window = self.window {
            NXCommonUtils.openPanel(parentWindow: window, allowMultiSelect: true, completion: action)
        }
    }
    //command script import /usr/local/opt/chisel/libexec/fblldb.py
    
    @IBAction func onCancelImage(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    @IBAction func onProtect(_ sender: Any) {
        let paths = selectedFile.map() { $0.url!.path }
        var emptyFileArray = [String]()
        
        for path in paths {
            if NXCommonUtils.fileSize(url: path) == 0 {
                let fileName = path.components(separatedBy: NSCharacterSet(charactersIn: "/") as CharacterSet).last
                emptyFileArray.append(fileName!)
             
            }
        }
        
        if emptyFileArray.count > 0{
            var display = String()
            display.append(String(format: "\n"))
            for temp in emptyFileArray{
                display.append(temp)
                display.append(String(format: "\n"))
            }
            
            let message = String(format: NSLocalizedString("FILE_OPERATION_PROTECT_EMPTY_FILE", comment: ""), display)
            NSAlert.showAlert(withMessage: message)
            return
        }
        
        
        var rights: NXRightObligation?
        var  tags: [String: [String]]?
        if (protectType == .project || protectType == .local || protectType == .workspace) {
            if companyDefinedBtn.state == NSControl.StateValue.on {
                guard let tag = tagTemplateView?.getTags() else {
                    let message = "PROJECT_FILES_PROTECT_MANDATORY_NO".localized
                    NSAlert.showAlert(withMessage: message)
                    return
                }
                tags = tag
            } else {
                guard let right = rightsView?.rights else {
                    NSAlert.showAlert(withMessage: "Please chose the rights")
                    return
                }
                rights = right
            }
        } else {
            guard let right = rightsView?.rights else {
                NSAlert.showAlert(withMessage: "Please chose the rights")
                return
            }
            rights = right
        }
        
        if let expiry = rights?.expiry,
            NXClient.isExpiryForever(expiry: expiry) {
            NSAlert.showAlert(withMessage: "EXPIRY_CANNOT_SHARE".localized)
            return
        }
        
        
        startAnimation()
        if tags != nil {
            NXClient.getCurrentClient().getRightObligationWithTags(totalProject: (self.projectModel != nil) ? self.projectModel?.sdmlProject : (syncFile?.file as? NXProjectFileModel)?.project?.sdmlProject, isWorkspace: protectType == .workspace, tags: tags!) { (nxObligation, error) in
                guard let right = nxObligation else {
                    self.stopAnimation()
                    
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.commonFailed(reason: .networkUnreachable) = sdmlError {
                        NSAlert.showAlert(withMessage: "WARNING_GET_RIGHT_FAILED".localized)
                    } else {
                        NSAlert.showAlert(withMessage: "Unknown error")
                    }
                    
                    return
                }
                self.delegate?.nextCreateProjectFile(selectedFile: self.selectedFile, tags: tags!, destPath: self.destinationString, type: self.protectType, right: right)
                }
        } else {
            
            if protectType == .myVaultShared{
               stopAnimation()
                self.delegate?.nextCreateProtectedAndSharedNXLFile(selectedFile: self.selectedFile, right: rights, tags: tags, destPath: self.destinationString, type: self.protectType )
                return
            }

            protectFile(paths: paths, rights: rights, tags: tags) {(files,failedFiles) in
                self.stopAnimation()
                
                // If any file failed, show it.
                if files.count < paths.count {
                    let successedCount = files.count
                    let failedCount = paths.count - files.count
                    NXToastWindow.sharedInstance?.toast("\(successedCount) success, \(failedCount) failed.")
                }
                
              
                if files.count > 0 {
                    self.delegate?.protectFinish(files: files, right: rights, tags: tags, destPath: self.destinationString, type: self.protectType)
                }
                
                if failedFiles.count > 0
                {
                    var failedFileArray = [String]()
                    for path in failedFiles {
                        
                        let fileName = path.components(separatedBy: NSCharacterSet(charactersIn: "/") as CharacterSet).last
                        failedFileArray.append(fileName!)
                    }
                    
                    if failedFileArray.count > 0{
                        var display = String()
                        display.append(String(format: "\n"))
                        for temp in failedFileArray{
                            display.append(temp)
                            display.append(String(format: "\n"))
                        }
                        
                        let message = String(format: NSLocalizedString("FILE_OPERATION_PROTECT_FAILED_FILE", comment: ""), display)
                
                        NSAlert.showAlert(withMessage: message, dismissClosure: {_ in
                            DispatchQueue.main.async {
                                self.delegate?.onProtectFailed()
                            }
                        })
                        return
                    }
                }
            }
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
//    private func downloadFile(file: NXFileBase) {
//        startAnimation()
//        repositoryfile = file
//        guard !file.isKind(of: NXFolder.self) else {
//            return
//        }
//
//        let data = downloadData(file: file, Path: "", fileSource: .other, needOpen: false)
//
//        let result = DownloadUploadMgr.shared.downloadFile(file: file, filePath: nil, delegate: self, data: data)
//        if !result.0 {
//            let message = NSLocalizedString("HOME_SHARE_DOWNLOAD_FAILED", comment:"")
//            NSAlert.showAlert(withMessage: message, dismissClosure: {_ in
//                self.delegate?.onProtectFailed()
//            })
//            return
//        } else {
//            downloadOrUploadId = result.1
//        }
//    }
    
    private func checkFiles(urls: [URL]) -> Bool {
        var result = true
        
        startAnimation()
        for url in urls {
            let isNXL = NXClient.isNXLFile(path: url.path)
            if isNXL == true {
                result = false
                break
            }
        }

        // Show alert.
        if result == false {
            let message = NSLocalizedString("FILE_OPERATION_PROTECT_FAILED", comment: "")
            NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: { _ in
                self.delegate?.onProtectFailed()
            })
        }
        stopAnimation()
        return result
    }

    private func protectFile(paths: [String], rights: NXRightObligation?, tags: [String: [String]]?, completion: @escaping ([NXNXLFile],[String]) -> ()) {
        var result = [NXNXLFile]()
        var failed = [String]()
        result.reserveCapacity(paths.count)
        let names = paths.map { path -> String in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return name
            }.filter { (name) -> Bool in
              return  name.contains("*") || name.contains("?") || name.contains("<") || name.contains("|") || name.contains(">") || name.contains(":")
        }
        
        if names.count > 0 {
            self.stopAnimation()
            NSAlert.showAlert(withMessage: #"We don't support to protect a file, which the file name contains any of the following characters: \ / : * ? < > |"#)
            return
        }
        
        let group = DispatchGroup()
        for path in paths {
            
            group.enter()
            if protectType == .local {
                NXClient.getCurrentClient().protectFileToLocal(path: path, right: (rights != nil ? rights : nil), tags: (rights != nil ? nil : tags), destPath: destinationString) { (file, error) in
                    if let file = file {
                        let nxFile = NXSyncFile(file: file as NXFileBase)
                        let status = NXSyncFileStatus()
                        status.status = .completed
                        nxFile.syncStatus = status
                        nxFile.syncStatus?.status = .completed
                    NotificationCenter.default.post(name: NXNotification.trayViewUpdated.notificationName,object: file)
                    NotificationCenter.post(notification: NXNotification.systembucketProtectSuccess, object: nxFile)

                        result.append(file)
                    } else {
                         failed.append(path)
                        debugPrint(error as Any)
                       
                    }
                    group.leave()
                }
            } else {
                let parentFile: SDMLNXLFile?
                if protectType == .project {
                    parentFile = (projectModel != nil ? projectModel?.sdmlProject?.getFileManager().getRootFolder() : syncFile?.file.sdmlBaseFile as? SDMLProjectFile)
                } else {
                    parentFile = (syncFile?.file.sdmlBaseFile as? SDMLNXLFile)
                }
                    
                NXClient.getCurrentClient().protectFile(type: protectType, path: path, right: (rights != nil ? rights : nil), tags: (rights != nil ? nil : tags), parentFile: parentFile) { (file, error) in
                    if let file = file {
                        if self.protectType == .project {
                            NotificationCenter.default.post(name: NXNotification.projectProtected.notificationName, object: file)
                        } else if self.protectType == .myVault {
                            NotificationCenter.default.post(name: NXNotification.myVaultProtected.notificationName, object: file)
                        } else if self.protectType == .workspace {
                            NotificationCenter.default.post(name: NXNotification.workspaceProtected.notificationName, object: file)
                        }
                        
                        let nxFile = NXSyncFile(file: file as NXFileBase)
                        let status = NXSyncFileStatus()
                            status.status = .waiting
                            nxFile.syncStatus = status
                            nxFile.syncStatus?.status = .waiting
                        NotificationCenter.post(notification: NXNotification.waitingUpload, object: nxFile)
                            result.append(file)
                        
                    } else {
                        debugPrint(error as Any)
                        failed.append(path)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(result,failed)
        }
    }

    private func protectRepositoryFile(file: NXFileBase) {
        startAnimation()
    }
}

//extension NXHomeProtectConfigureView: DownloadUploadMgrDelegate {
//    func updateProgress(id: Int, data: Any?, progress: Float) {
//    }
//
//    func downloadUploadFinished(id: Int, data: Any?, error: NSError?) {
//        downloadOrUploadId = nil
//
//        if let uploadData = data as? uploadData {
//            DispatchQueue.main.async {
//                self.stopAnimation()
//            }
//            let url = URL(fileURLWithPath: uploadData.srcPath)
//            if let error = error {
//                DispatchQueue.main.async {
//                    if error.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue  {
//                        NXCommonUtils.showNotification(title: "SkyDRM", content: "Upload file: " + url.lastPathComponent + " failed:\n" + NSLocalizedString("UploadVC_File_ACCESS_DENIED_TIP", comment: ""))
//                    } else if error.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED.rawValue {
//                        NXCommonUtils.showNotification(title: "SkyDRM", content: NSLocalizedString("FILE_OPERATION_MYVAULT_USED_UP_STORAGE_UPLOAD", comment: ""))
//                    } else {
//                        NXCommonUtils.showNotification(title: "SkyDRM", content: NSLocalizedString("FILE_OPERATION_UPLOAD_FAILED", comment: ""))
//                    }
//                }
//            }
//            else {
//                if uploadData.bTempNxlFile {
//                    NXCommonUtils.removeTempFileAndFolder(tempPath: url)
//                }
//
//                DispatchQueue.main.async {
//                    NXCommonUtils.showNotification(title: "SkyDRM", content: "The rights-protected file " + url.lastPathComponent + " has been upload my vault successfully")
//                }
//
//                NotificationCenter.default.post(name: NSNotification.Name("myVaultDidChanged"),
//                                                object: nil,
//                                                userInfo: nil)
//            }
//        } else if let data = data as? downloadData {
//            if error == nil {
//            } else {
//                try? FileManager.default.removeItem(atPath: data.Path)
//
//                var message = NSLocalizedString("HOME_PROTECT_DOWNLOAD_FAILED", comment:"")
//
//                if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
//                    message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
//                }
//
//                NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: {_ in
//                    self.delegate?.onProtectFailed()
//                })
//            }
//        }
//    }
//}

extension NXHomeProtectConfigureView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.onCancel(self)
    }
}
