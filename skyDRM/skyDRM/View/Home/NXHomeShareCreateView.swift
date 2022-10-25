//
//  NXHomeShareCreateView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 01/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
protocol NXHomeShareCreateViewDelegate: NSObjectProtocol {
    func onCreateFinish(info: NXSelectedFile, rights: NXLRights)
    func onCreateFailed()
}

class NXHomeShareCreateView: NXProgressIndicatorView {
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var middleView: NSView!
    @IBOutlet weak var createBtn: NSButton!
    @IBOutlet weak var box: NSBox!
    
    fileprivate var rightsView: NXRightsView?
    fileprivate var repositoryfile = NXFileBase()
    fileprivate var downloadOrUploadId:Int? = nil
    
    var selectedFile: NXSelectedFile!
    weak var delegate: NXHomeShareCreateViewDelegate?
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        self.window?.delegate = self
        
        createBtn.wantsLayer = true
        createBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        createBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: createBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, createBtn.title.count))
        createBtn.attributedTitle = titleAttr
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
        
        rightsView = NXCommonUtils.createViewFromXib(xibName: "NXRightsView", identifier: "rightsView", frame: nil, superView: middleView) as? NXRightsView
        
        // Init watermark and expiry from preference.
        var watermark: NXFileWatermark?
        var expiry: NXFileExpiry?
        if let text = NXClient.getCurrentClient().getUserPreference()?.getDefaultWatermark().getText() {
            watermark = NXFileWatermark(text: text)
        }
        if let preferenceExpiry = NXClient.getCurrentClient().getUserPreference()?.getDefaultExpiry() {
            expiry = NXCommonUtils.transform(from: preferenceExpiry)
        }
        rightsView?.set(watermark: watermark, expiry: expiry)
    }
    
    @IBAction func onClose(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    @IBAction func onCancel(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    @IBAction func onCreate(_ sender: Any) {
    }
    
    private func downloadFile(file: NXFileBase) {
        startAnimation()
        repositoryfile = file
        guard !file.isKind(of: NXFolder.self) else {
            return
        }
        
        let data = downloadData(file: file, Path: "", fileSource: .other, needOpen: false)
        
        let result = DownloadUploadMgr.shared.downloadFile(file: file, filePath: nil, delegate: self, data: data)
        if !result.0 {
            let message = NSLocalizedString(NSLocalizedString("HOME_SHARE_DOWNLOAD_FAILED", comment: ""), comment:"")
            NSAlert.showAlert(withMessage: message, dismissClosure: {_ in
                self.delegate?.onCreateFailed()
            })
            return
        } else {
            downloadOrUploadId = result.1
        }
    }
    
    private func downloadRangeFile(file: NXFileBase) {
        startAnimation()
        repositoryfile = file
        let result = DownloadUploadMgr.shared.rangeDownloadFile(file: file, length: 0x4000, delegate: self, data: rangeDownloadData(file: file, cachePath: ""))
        if result.0 {
            downloadOrUploadId = result.1
        }
    }
    
    private func showLocalFileRights(file: NXFileBase) {
        startAnimation()
        showRigths(file: file)
    }
    fileprivate func showRigths(file: NXFileBase, tempPath: String? = nil) {
        
        let localPath = tempPath ?? file.localPath
        
        let removeTempFile: (String?) -> Void = {
            path in
            if let path = path {
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
            }
        }
        
        guard
            FileManager.default.fileExists(atPath: localPath),
            let nxclient = NXLoginUser.sharedInstance.nxlClient
            else {
                
                removeTempFile(tempPath)
                
                self.delegate?.onCreateFailed()
                stopAnimation()
                return
        }
        
        let fileURL = URL(fileURLWithPath: localPath)
        if !nxclient.isNXLFile(fileURL) {
            removeTempFile(tempPath)
            stopAnimation()
            
            return
        }
        
        nxclient.getNXLFileRights(fileURL) {
            (rights, isSteward, error) in
            if error != nil {
                
                if (error as NSError?)?.code == 403 || (error as NSError?)?.code == 404 {
                    self.sendLogToRMS(file: file, tempPath: tempPath)
                    NSAlert.showAlert(withMessage: NSLocalizedString("HOME_SHARE_NO_SHARE_RIGHTS", comment: ""), informativeText: "", dismissClosure: {_ in
                        self.delegate?.onCreateFailed()
                    })
                } else {
                    removeTempFile(tempPath)
                    
                    let message = NSLocalizedString((error?.localizedDescription)!, comment: "")
                    NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: {_ in
                        self.delegate?.onCreateFailed()
                    })
                }
                
                self.stopAnimation()
                return
            }
            
            DispatchQueue.main.async {
            }
            
            self.stopAnimation()
            
            if rights?.getRight(.NXLRIGHTSHARING) == false && !isSteward {
                self.sendLogToRMS(file: file, tempPath: tempPath)
                let message = NSLocalizedString("HOME_SHARE_NO_SHARE_RIGHTS", comment: "")
                NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure:{_ in
                    self.delegate?.onCreateFailed()
                })
            } else {
                removeTempFile(tempPath)
            }
            
        }
    }
    
    private func sendLogToRMS(file: NXFileBase, tempPath: String?){
        
        let removeTempFile: (String?) -> Void = {
            path in
            if let path = path {
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
            }
        }
        
        let fileURL = URL(fileURLWithPath: tempPath ?? file.localPath)
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
}

extension NXHomeShareCreateView: DownloadUploadMgrDelegate {
    func updateProgress(id: Int, data: Any?, progress: Float) {
    }
    
    func downloadUploadFinished(id: Int, data: Any?, error: NSError?) {
        downloadOrUploadId = nil
        
        if let data = data as? downloadData {
            if error == nil {
                showRigths(file: self.repositoryfile)
            } else {
                try? FileManager.default.removeItem(atPath: data.Path)
                
                var message = NSLocalizedString("HOME_SHARE_DOWNLOAD_FAILED", comment:"")
                
                if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                    message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                }
                
                NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: {_ in
                    self.delegate?.onCreateFailed()
                })
            }
        } else if let data = data as? rangeDownloadData {
            
            if error != nil {
                
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: data.cachePath))
                
                var message = NSLocalizedString("HOME_SHARE_DOWNLOAD_FAILED", comment:"")
                if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                    message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                }
                
                NSAlert.showAlert(withMessage: message, informativeText: "") {
                    _ in
                    self.delegate?.onCreateFailed()
                }
                
                return
            }
            
            showRigths(file: self.repositoryfile, tempPath: data.cachePath)
            
        }
    }
}

extension NXHomeShareCreateView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.onClose(self)
    }
}
