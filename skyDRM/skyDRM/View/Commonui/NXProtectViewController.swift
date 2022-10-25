//
//  NXProtectViewController.swift
//  skyDRM
//
//  Created by bill.zhang on 3/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProtectViewControllerDelegate: NSObjectProtocol {
    func close()
}

class NXProtectViewController: NSViewController {

    @IBOutlet var contentView: NSView!
    
    fileprivate var protectView : NXFileProtectView?
    
    var fileProtectType : NXFileProtectType?
    var file: NXFileBase?
    
    var isNXLFile:Bool?
    var rights:NXLRights? = nil
    var isSteward:Bool? = nil
    
    fileprivate var waitView : NXWaitingView?
    fileprivate var downloadOrUploadId : Int? = nil
    fileprivate var bClosed = false
    
    /// not support cancel when share file currently
    fileprivate var isShared = false
    
    weak var delegate: NXProtectViewControllerDelegate?
    
    var resharingEmails: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.delegate = self
        self.view.window?.styleMask = [.titled ,.closable, .miniaturizable]
        if isShared {
            _ = self.view.window?.styleMask.remove(.closable)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func doWorkWithoutDownload() {
        displayUI()
        showRights(with: file)
    }
    
    func doWork() {
        displayUI()
        
        if file?.boundService == nil {
            showRights(with: file)
            return
        }
        
        if fileProtectType == .share {
            if file?.serviceType.int32Value == ServiceType.kServiceSkyDrmBox.rawValue {
                if NXCommonUtils.isNXLFile(path: (file!.localPath != "") ? file!.localPath : file!.name) {
                    downloadRangeFile(file: file!)
                } else {
                }
                
                return
                
            } else if file?.serviceType.int32Value == ServiceType.kServiceMyVault.rawValue {
                if let file = file as? NXNXLFile {
                    getMetaData(file: file)
                    return
                } else if let file = file as? NXSharedWithMeFile {
                    if let rights = file.rights {
                        _ = NXCommonUtils.convertFileRightToNXLFileRight(rights: rights)
                    }
                
                    return
                }
            }
        }
        
        waitView = NXCommonUtils.createWaitingView(superView: self.view)
        
        let data = downloadData(file: file!, Path: "", fileSource: .other, needOpen: false)
        
        let result = DownloadUploadMgr.shared.downloadFile(file: file!, filePath: nil, delegate: self, data: data)
        if !result.0 {
            waitView?.removeFromSuperview()
            let message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
            NSAlert.showAlert(withMessage: message)
            return
        } else {
            downloadOrUploadId = result.1
        }
    }
    
    private func displayUI() {
        guard let _ = fileProtectType, let _ = file else {
            return
        }
        if fileProtectType == .share {
            self.title = NSLocalizedString("Share", comment: "")
        } else {
            self.title = NSLocalizedString("Protect", comment: "")
        }
        
        if (file?.isKind(of: NXFolder.self))! {
            return
        }
        
        showShareProtectView()
    }
    
    func showRights(with file: NXFileBase?, tempPath: String? = nil) {
        
        let removeTempFile: (String?) -> Void = {
            path in
            if let path = path {
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
            }
        }
        
        guard let file = file else {
            removeTempFile(tempPath)
            self.waitView?.removeFromSuperview()
            return
        }
        
        let localPath = tempPath ?? file.localPath
        
        if FileManager.default.fileExists(atPath: localPath) == false {
            removeTempFile(tempPath)
            self.waitView?.removeFromSuperview()
            return
        }
        
        _ = URL(fileURLWithPath: localPath)
        
        if NXClient.isNXLFile(path: localPath) == false {
            removeTempFile(tempPath)
            isNXLFile = false
            self.waitView?.removeFromSuperview()
            return
        }
        isNXLFile = true
        
        if self.fileProtectType == .protect {
            let message = NSLocalizedString("FILE_OPERATION_PROTECT_FAILED", comment: "")
            NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: { _ in
                self.close()
            })
            return
        }
    }
    
    func showShareProtectView() {
        removeAllViews()
        protectView = NXFileProtectView.createFileProtectView(frame: contentView.bounds, withFile: file!, type: fileProtectType!)
        protectView?.delegate = self
        contentView.addSubview(protectView!)
        protectView?.translatesAutoresizingMaskIntoConstraints = false
        
        contentView .addConstraint(NSLayoutConstraint(item: protectView ?? protectView!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0))
        contentView .addConstraint(NSLayoutConstraint(item: protectView ?? protectView!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0))
        contentView .addConstraint(NSLayoutConstraint(item: protectView ?? protectView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
        contentView .addConstraint(NSLayoutConstraint(item: protectView ?? protectView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
    }
    
    func removeAllViews() {
        waitView?.removeFromSuperview()
        protectView?.removeFromSuperview()
    }
    
    private func sendLogToRMS(file: NXFileBase, tempPath: String? = nil){
        
        let removeTempFile: (String?) -> Void = {
            path in
            if let path = path {
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
            }
        }
        
        let fileURL = tempPath != nil ? URL(fileURLWithPath: tempPath!) : URL(fileURLWithPath: file.localPath)
        
        NXLoginUser.sharedInstance.nxlClient?.getStewardForNXLFile(fileURL, withCompletion: { (steward, duid, error) in
            
            removeTempFile(tempPath)
            
            guard
                let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId),
                let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)
                else { return }
            
            let logService = NXLogService(userID: userId, ticket: ticket)
            
            let putModel = NXPutActivityLogInfoRequestModel()
            let time:TimeInterval = NSDate().timeIntervalSince1970 ;
            let accessTime = Int(time*1000)
            
            let duidValue = file.getNXLID() ?? duid
            putModel.duid = duidValue ?? ""
            putModel.owner = steward ?? ""
            putModel.operation = OperationEnum.Reshare.rawValue
            putModel.repositoryId = file.boundService?.repoId ?? " "
            putModel.filePathId = " "
            putModel.fileName = file.name
            putModel.filePath = file.fullServicePath
            putModel.activityData = " "
            putModel.accessTime = accessTime
            putModel.userID = userId
            putModel.accessResult = 0
            
            logService.putActivityLogInfoWith(activityLogInfoRequestModel: putModel)
        })
    }
    
    private func downloadRangeFile(file: NXFileBase) {
        waitView = NXCommonUtils.createWaitingView(superView: self.view)
        
        let result = DownloadUploadMgr.shared.rangeDownloadFile(file: file, length: 0x4000, delegate: self, data: rangeDownloadData(file: file, cachePath: ""))
        if result.0 {
            downloadOrUploadId = result.1
        }
    }
    
    private func getMetaData(file: NXNXLFile) {
        guard
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            else { return }
        
        let service = MyVaultService(withUserID: userId, ticket: ticket)
        service.delegate = self
        _ = service.getMetaData(file: file)
    }
    
}

extension NXProtectViewController : NXFileProtectViewDelegate {
    func protectAction(forFile file: NXFileBase?, withRights rights: NXLRights?) {
        protectView?.confirmButton.isEnabled = false
        
        guard let file = file,
            let _ = rights else {
            return
        }
        
        waitView = NXCommonUtils.createWaitingView(superView: self.protectView!)
        
        // source file path
        _ = URL(fileURLWithPath: file.localPath)
        
        // compose nxl file name with time stamp
        let triedName = tryGetGoogleConvertName(file: file)
        let fileName = NXCommonUtils.createNXLFileNameWithTimeStamp(originFileName: triedName)
        
        // get temp folder
        let gitFolder = NXCommonUtils.getTempFolder()
        
        // temp file path
        _ = gitFolder?.appendingPathComponent(fileName, isDirectory: false)
    }
    
    func shareAction(forFile file:NXFileBase?, withRights rights:NXLRights?, emails:[String]?, shareType: NSInteger?, comment: String?) {
        guard emails?.count != 0 else {
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_INVALID_EMAIL", comment: ""))
            return;
        }
        guard let file = file else {
            return
        }
        
        //TODO
        
        //2 check email
        guard let sharedEmails = emails else {
            return
        }
        
        if sharedEmails.count == 0 {
            //at least one vaild email address
            return
        }
        
        //3 share.
        waitView = NXCommonUtils.createWaitingView(superView: self.protectView!)
        
        if let file = file as? NXSharedWithMeFile {
            let service = NXSharedWithMeService()
            service.delegate = self
            self.resharingEmails = sharedEmails
            let str = sharedEmails.joined(separator: ",")
            service.reshareFile(file: file, shareWith: str)
            return
        }
        
        // Not support cancel share operation now, so just remove close window
        
        isShared = true
        _ = self.view.window?.styleMask.remove(.closable)
        
        
        
        if file.serviceType.int32Value == ServiceType.kServiceSkyDrmBox.rawValue ||
            file.serviceType.int32Value == ServiceType.kServiceMyVault.rawValue {
            
            let repoFile = NXLRepoFile()
            let triedName = tryGetGoogleConvertName(file: file)
            repoFile.fileName = triedName
            repoFile.filePath = file.fullPath
            repoFile.filePathId = file.fullServicePath
            repoFile.repoId = file.boundService?.repoId
            
            _ = sharedEmails.map() { ["email": $0] }
        } 
    }
    
    func cancelAction(forFile file: NXFileBase?, withProtectType type: NXFileProtectType?) {
        DispatchQueue.main.async {
            self.close()
        }
    }
    
    func close() {
        if downloadOrUploadId != nil {
            DownloadUploadMgr.shared.cancel(id: downloadOrUploadId!)
        }
        
        bClosed = true
        
        self.removeAllViews()
        self.presentingViewController?.dismiss(self)
        MaskView.sharedInstance.removeFromSuperview()
        
        self.delegate?.close()
    }
    private func tryGetGoogleConvertName(file: NXFileBase) -> String {
        if let ext = file.extraInfor[NXFileBase.Constant.kGoogleExportExtension] as? String,
            !file.name.hasSuffix(ext){
            return file.name.appending(ext)
        }
        return file.name
    }
}

extension NXProtectViewController : DownloadUploadMgrDelegate {
    func updateProgress(id: Int, data: Any?, progress: Float) {
        DispatchQueue.main.async {
            self.protectView?.progressValue = Double(progress)
            self.protectView?.progressIndicator.isHidden = false
        }
    }
    
    func downloadUploadFinished(id: Int, data: Any?, error: NSError?) {
        DispatchQueue.main.async {
            self.protectView?.progressValue = 1.0
            self.protectView?.progressIndicator.isHidden = true
            self.downloadOrUploadId = nil
            
            if let data = data as? uploadData {
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: data.srcPath))
        
                let url = URL(fileURLWithPath: data.srcPath)
                
                if error == nil {
                    let content = "The rights-protected file " + url.lastPathComponent + " has been upload my vault successfully"
                    NXCommonUtils.showNotification(title:"SkyDRM", content:content)
                    
                    /// send notification when protect successfully
                    NotificationCenter.default.post(name: NSNotification.Name("myVaultDidChanged"),
                                                    object: nil,
                                                    userInfo: nil)
                } else {
                    if error?.code != NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue {
                        if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED.rawValue  {
                            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_MYVAULT_USED_UP_STORAGE_UPLOAD", comment: ""), dismissClosure: {_ in
                                self.close()
                            })
                        } else if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue  {
                            NSAlert.showAlert(withMessage: "Upload file: " + url.lastPathComponent + " failed:\n" + NSLocalizedString("UploadVC_File_ACCESS_DENIED_TIP", comment: ""), dismissClosure: {_ in
                                self.close()
                            })
                        } else {
                            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_UPLOAD_FAILED", comment: ""), dismissClosure: {_ in
                                self.close()
                            })
                        }
                    }

                    return
                }
        
                self.protectView?.confirmButton.isEnabled = true
                self.waitView?.removeFromSuperview()
        
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 2000)) {
                    self.close()
                }
            } else if let data = data as? downloadData {
                if error == nil {
                    if let file = self.file {
                        self.tryUpdateFileAfterDownload(file: file)
                        self.showRights(with: file)
                    }
                } else {
                    try? FileManager.default.removeItem(atPath: data.Path)
                    
                    if error?.code != NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue {
                        var message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
                        
                        if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                            message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                        }
                        else if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED.rawValue {
                            message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NOT_SUPPORT_SUCH_FILE", comment: "")
                        }
                        
                        NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: {_ in
                            self.close()
                        })
                    }
                }
            } else if let data = data as? rangeDownloadData {
                if error != nil {
                    
                    NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: data.cachePath))
                    
                    if error?.code != NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue {
                        var message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
                        
                        if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                            message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                        }
                        
                        NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: {_ in
                            self.close()
                        })
                    }
                    return
                }
                
                self.showRights(with: self.file, tempPath: data.cachePath)
            }
        }
    }
    private func tryUpdateFileAfterDownload(file: NXFileBase) {
        if let exportExtension = file.extraInfor[NXFileBase.Constant.kGoogleExportExtension] as? String {
            if !file.localPath.hasSuffix(exportExtension) {
                file.localPath = file.localPath.appending(exportExtension)
                _ = DBFileBaseHandler.shared.updateFileNode(fileBase: file)
            }
        }
    }
}

extension NXProtectViewController:NSWindowDelegate {
    private func windowShouldClose(_ sender: Any) -> Bool {
        self.close()
        return true;
    }
}

extension NXProtectViewController: NXServiceOperationDelegate {
    func getMetaDataFinished(servicePath: String?, error: NSError?) {
        DispatchQueue.main.async {
            self.waitView?.removeFromSuperview()
        }
        
        let failedHandler: (String) -> Void = {
            message in
            
            NSAlert.showAlert(withMessage: message, informativeText: "") {
                _ in
                self.close()
            }
        }
        
        if error != nil {
            let message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
            failedHandler(message)
            return
        }
        
        guard
            let file = self.file as? NXNXLFile,
            let rights = file.rights
            else {
                let message = NSLocalizedString("HOME_SHARE_DOWNLOAD_FAILED", comment:"")
                failedHandler(message)
                return
        }
        
        
        _ = NXCommonUtils.convertFileRightToNXLFileRight(rights: rights)
        DispatchQueue.main.async {

        }
    }
}

extension NXProtectViewController: NXSharedWithMeServiceDelegate {
    func reshareFinish(newTransactionId: String?, sharedLink: String?, alreadySharedList: [String]?, newSharedList: [String]?, error: Error?) {
        
        if error != nil {
            if let backendError = error as? BackendError {
                switch backendError {
                case .failResponse(let reason):
                    if reason == "You are not allowed to share this file."
                    || reason == "File has been revoked" {
                        NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHAREWITHME_FAILED", comment: ""), informativeText: "") { _ in
                            self.close()
                        }
                        return
                    }
                default:
                    break
                }
            }
            
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_FAILED", comment: ""), informativeText: "") { _ in
                self.close()
            }
            return
        }
        
        if let newSharedList = newSharedList,
            !newSharedList.isEmpty {
            let namelist = newSharedList.joined(separator: ",")
            NXCommonUtils.showNotification(title:"SkyDRM", content: String(format: NSLocalizedString("SHARE_NXLFILE_SUCCESS", comment: ""), namelist))
        }
        
        if let alreadySharedList = alreadySharedList,
            let resharingEmails = self.resharingEmails {
            let resharingSet = Set(resharingEmails)
            let alreadySet = Set(alreadySharedList)
            let hasSharedSet = resharingSet.intersection(alreadySet)
            if !hasSharedSet.isEmpty {
                let hasSharedStr = hasSharedSet.joined(separator: ",")
                NSAlert.showAlert(withMessage: String(format: NSLocalizedString("RESHARE_HAS_ALREADY_SHARED", comment: ""), hasSharedStr))
            }
        }
        
        DispatchQueue.main.async {
            self.close()
        }
    }
}
