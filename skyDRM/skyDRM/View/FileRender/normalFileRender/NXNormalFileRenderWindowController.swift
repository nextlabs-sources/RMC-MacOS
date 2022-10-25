//
//  NXNormalFileRenderWindowController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/12/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import Quartz
import WebKit
import SDML

class NXNormalFileRenderWindowController: NXFileRenderWindowController {
    
    @IBOutlet var printItem: NSToolbarItem!
    @IBOutlet var shareItem: NSToolbarItem!
    @IBOutlet var propertyItem: NSToolbarItem!
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var targetVC: NSViewController!
    var normalRenderView:QLPreviewView? = nil
    var vdsRenderView:WebView? = nil
    var targetRenderView:NSView? = nil
    var overlayInfo:NXOverlayInfo? = nil
    private var canAddFileToProject = false
    var isPDF = false
    
 override var windowNibName:NSNib.Name? {
        return NSNib.Name("NXNormalFileRenderWindowController")
    }
    
    class func loadFromNib() -> NXNormalFileRenderWindowController{
        let windowController = NXNormalFileRenderWindowController()
        windowController.window?.delegate = windowController
        return windowController
    }
    deinit{
        waitingView?.removeFromSuperview()
        
        if isSwitch {
            return
        }
        
        isPDF = false
        if self.nxRenderProxy.nxFileItem.autoDelete == true,
            let tempPath = self.nxRenderProxy.nxFileItem.tempFilePath {
            NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: tempPath))
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        location()
        self.window?.contentViewController = targetVC
    }
    
    // International adaptation
    fileprivate func location() {
        printItem.label = "FILE_RENDER_PRINT".localized
        propertyItem.label = "FILE_RENDER_PROPERTY".localized
        shareItem.label = "FILE_RENDER_SHARE".localized
        
        printItem.isEnabled = false
        shareItem.isEnabled = false
        propertyItem.isEnabled = false
        
        printItem.toolTip = "Print"
        shareItem.toolTip = "Share"
        propertyItem.toolTip = "View File Info"
    }
    
    func initToolbarItem(fileItem: NXFileBase){
        if !(fileItem is NXNXLFile) {
            printItem.view?.removeFromSuperview()
            shareItem.toolTip = "Protect a File"
            shareItem.image = NSImage(named: "protectinmenu")
            propertyItem.toolTip = "Protect & Share"
            propertyItem.image = NSImage(named:"shareinmenu")
        }
    }
    
    fileprivate func updateToolbarItem(){
        if !(self.fileItem is NXNXLFile) {
            shareItem.isEnabled = true
            propertyItem.isEnabled = true
            return
        }
        
        propertyItem.isEnabled = true
        
        if fileItem?.sdmlBaseFile?.getKind() == nil{
            if self.nxRenderProxy.nxFileItem.isTag == true {
                shareItem.toolTip = "Add to Project"
                shareItem.image = NSImage(named: "addfiletoprojectmenu")
                
                if self.nxRenderProxy.nxFileItem.rightOb?.rights.contains(.extract) == true {
                    canAddFileToProject = true
                    shareItem.isEnabled = true
                }
            }
        }else{
            if ((self.fileItem?.sdmlBaseFile as? SDMLProjectFile) != nil), self.nxRenderProxy.nxFileItem.isTag == true{
                shareItem.toolTip = "Add to Project"
                shareItem.image = NSImage(named: "addfiletoprojectmenu")
                
                if self.nxRenderProxy.nxFileItem.rightOb?.rights.contains(.extract) == true {
                    canAddFileToProject = true
                    shareItem.isEnabled = true
                }
            }
        }
        
        if let isSteward = self.nxRenderProxy.nxFileItem.isSteward, isSteward == true, self.nxRenderProxy.nxFileItem.isTag != true {
            printItem.isEnabled = true
        } else {
            if self.nxRenderProxy.nxFileItem.rightOb?.rights.contains(.print) == true {
                printItem.isEnabled = true
            }
        }
        
        if let outBoxFile = self.fileItem?.sdmlBaseFile as? SDMLOutBoxFile {
            if outBoxFile.getOutBoxFileType() == .myVaultFile {
                self.shareItem.isEnabled = true
            }
        }
    }
    
    fileprivate func renderFile(fileURL: URL){
        if targetRenderView != nil {
            targetRenderView?.removeFromSuperview()
        }
        
        if targetRenderView is QLPreviewView {
            normalRenderView?.previewItem = fileURL as QLPreviewItem
        }else if targetRenderView is WebView{
            vdsRenderView?.mainFrame.load(NSURLRequest(url: fileURL) as URLRequest)
        }
        
        targetRenderView?.wantsLayer = true
        self.window?.contentView?.addSubview(targetRenderView!)
        targetRenderView?.translatesAutoresizingMaskIntoConstraints = false
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: targetRenderView!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: targetRenderView!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0))
        
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: targetRenderView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: targetRenderView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
        
        self.afterOpenedFile()
    }
    
    fileprivate func renderFile(filePath path:String) {
        let fileURL = URL(fileURLWithPath: path)
        renderFile(fileURL: fileURL)
    }
    
    fileprivate func afterOpenedFile() {
        updateToolbarItem()
        self.validateToolbarItem(shareItem)
        self.validateToolbarItem(printItem)
        addOverlay()
    }
    
    func addOverlay() {
        guard let watermarkText = self.nxRenderProxy.nxFileItem.rightOb?.watermark else {
            return
        }
        
        self.overlayInfo = NXOverlayInfo(text: watermarkText.text)
        let watermark = NXWatermark(overlayInfo: self.overlayInfo!)
        let overlayView = NXOverlayView(watermark:watermark)
        
        overlayView.frame = (self.window?.contentView?.bounds)!
        self.window?.contentView?.addSubview(overlayView)
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0))
        if #available(OSX 10.14, *) {
            self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: isPDF ? -20:0))
        } else {
            self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0))
        }
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
    }
    
    @IBAction func onPrintClick(_ sender: Any) {
        let sendPrintLog: (Bool) -> Void = {
            isAllow in
            if let file = self.fileItem {
                NXCommonUtils.addLog(file: file, operation: "Print", isAllow: isAllow)
            }
        }
        
        if targetRenderView is WebView{
            sendPrintLog(true)
            var src = ""
            if NXFileRenderSupportUtil.isRemoteViewUsingCanvasByFileName(fileName: (self.fileItem?.name)!) == .CANVAS{
                src = "var na = document.getElementById('__viewer0-canvas');  na.style.height"
            }else if NXFileRenderSupportUtil.isRemoteViewUsingCanvasByFileName(fileName: (self.fileItem?.name)!) == .IMAGE{
                src = "var na = document.getElementById('imageWrapper');  na.style.height"
            }else{
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_RENDER_PRINT_UNSTART", comment:""))
            }
            
            let vdsFileHeight = vdsRenderView?.stringByEvaluatingJavaScript(from: src)
            guard vdsFileHeight != nil,
                vdsFileHeight != "" else {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_RENDER_PRINT_UNSTART", comment:""))
                return
            }
            
            let s2 = "var n = document.getElementsByClassName('cc-header'); n[0].clientHeight;"
            let headerHeight = vdsRenderView?.stringByEvaluatingJavaScript(from: s2)
            
            let s3 = "var t = document.getElementsByClassName('toolbarContainer'); t[0].clientHeight;"
            let barHeight = vdsRenderView?.stringByEvaluatingJavaScript(from: s3)
            
            let endIndex = vdsFileHeight!.index(vdsFileHeight!.endIndex, offsetBy: -2)
            let heightStr = String(vdsFileHeight![..<endIndex])
            
            let height = NSString(string: heightStr).floatValue
            
            let viewRect = CGRect(origin: CGPoint(x: (targetRenderView?.frame.origin.x)!, y: (targetRenderView?.frame.origin.y)! + (targetRenderView?.frame.size.height)! - CGFloat(height)),
                                  size: CGSize(width: (targetRenderView?.frame.size.width)!, height: CGFloat(height - NSString(string: barHeight!).floatValue - NSString(string: headerHeight!).floatValue)))
            let sEx = self.window?.convertToScreen(viewRect)
            
            let image = NXHPSPrintUtil.screenShot(sEx!)
            
            let picRect = NSRectFromCGRect(CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: (image?.size.width)!, height: (image?.size.height)!)))
            let imgView = NSImageView(frame: picRect)
            imgView.image = image
            
            let picPrint = NSPrintOperation(view: imgView)
            picPrint.canSpawnSeparateThread = true
            
            let printInfo = NSPrintInfo.shared
            printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
            printInfo.horizontalPagination = NSPrintInfo.PaginationMode.fit
            picPrint.printInfo = printInfo
            picPrint.jobTitle = fileItem?.name
            //picPrint.run()
            picPrint.runModal(for: self.window!, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            guard let filePath = self.nxRenderProxy.nxFileItem.tempFilePath else {
                return
            }
            
            //for not support print file type, show alert dialog.
            if self.targetRenderView is QLPreviewView,
                NXPrinter.supportPrint(filePath) == false {
                
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_RENDER_PRINT_NOT_SUPPORT", comment:""))
                
            } else {
                guard let printer = NXPrinter.createPrinter(filePath: filePath) else {
                    NSAlert.showAlert(withMessage: NSLocalizedString("FILE_RENDER_PRINT_NOT_SUPPORT", comment:""))
                    return
                }
                
                sendPrintLog(true)
                let result = printer.print(window: self.window!, overlayInfo: self.overlayInfo)
                if result == false {
                    NSAlert.showAlert(withMessage:NSLocalizedString("FILE_RENDER_PRINT_ERROR", comment:""))
                }
            }
        }
    }
    
    @IBAction func onShareClick(_ sender: Any) {
        if !(self.fileItem is NXNXLFile) {
            super.protect(filePath: fileItem?.localPath ?? "")
            return
        }
        
        if canAddFileToProject {
            super.addNXLToProject()
        } else {
            super.share()
        }
    }
    
    @IBAction func onPropertyClick(_ sender: Any) {
        if !(self.fileItem is NXNXLFile) {
            super.protectAndShare(filePath: fileItem?.localPath ?? "")
            return
        }
        
        super.showFileInfo()
    }
    
    func renderRemoteView(result: SDMLRemoteViewResult?, error: Error?) {
        guard error == nil else{
            NSAlert.showAlert(withMessage:NSLocalizedString("FILE_RENDER_NOT_AUTH", comment: ""), informativeText: "", dismissClosure:{_ in
                self.window?.close()
            })
            return
        }
        
        let url = URL(string: (result?.viewerURL)!)
        NXFileRenderSupportUtil.addCustomerCookie(url: url!, cookies: (result?.cookies)!)
        vdsRenderView = WebView(frame: (self.window?.contentView?.bounds)!, frameName: "vds view", groupName: "remote view")
        vdsRenderView?.frameLoadDelegate = self
        targetRenderView = vdsRenderView
        self.renderFile(fileURL: url!)
    }
    
    override func parseFileFinish(path: String, error: NSError?) {
        super.parseFileFinish(path: path, error: error)
        
        if error != nil {
            return
        }
        
        if NXFileRenderSupportUtil.shouldRemoteView(filePath: path) {
            DispatchQueue.main.async {
                self.waitingView?.isHidden = false
            }
            
            guard let nxlFile = self.fileItem?.sdmlBaseFile as? SDMLNXLFile else {
                
                // local file may has nil value for sdmlBaseFile property
                NXClient.getCurrentClient().remoteViewLocal(path: path) { [weak self]  (result, error) in
                    DispatchQueue.main.async {
                        self?.waitingView?.isHidden = true
                    }
                    self?.renderRemoteView(result: result, error: error)
                }
                
                return
            }
           
            if nxlFile is SDMLMyVaultFile {
                let repoId = NXCommonUtils.getLocalDriveRepoId()
                NXClient.getCurrentClient().remoteViewRepo(file: self.fileItem!, repoId: repoId) { [weak self] (result, error) in
                    DispatchQueue.main.async {
                        self?.waitingView?.isHidden = true
                    }
                    self?.renderRemoteView(result: result, error: error)
                }
            
            } else if nxlFile is SDMLProjectFile {
                let projectFile = nxlFile as? SDMLProjectFile
                NXClient.getCurrentClient().remoteViewProject(projectID:"\(projectFile!.getProjectId())", file: self.fileItem!){ [weak self]  (result, error) in
                    DispatchQueue.main.async {
                        self?.waitingView?.isHidden = true
                    }
                    self?.renderRemoteView(result: result, error: error)
                }
            }else{
                NXClient.getCurrentClient().remoteViewLocal(path: path) { [weak self]  (result, error) in
                    DispatchQueue.main.async {
                        self?.waitingView?.isHidden = true
                    }
                    self?.renderRemoteView(result: result, error: error)
                }
            }
        } else {
            
            if is3DPdf(path: path) {
                show3DPdf(path: path)
            } else {
                preview(path: path)
            }
        }
    }
    
    private func preview(path: String) {
        normalRenderView = QLPreviewView(frame: (self.window?.contentView?.bounds)!)
        targetRenderView = normalRenderView
        let pathUrl = URL(fileURLWithPath: path)
        if pathUrl.pathExtension.localizedLowercase == "pdf" {
            isPDF = true
        }
        self.renderFile(filePath: path)
    }
    
    // FIXME: 3D pdf crash, only watch 2D.
    private func is3DPdf(path: String) -> Bool {
//        let url = URL(fileURLWithPath: path)
//        if url.pathExtension.localizedLowercase == "pdf",
//            NXCommonUtils.isPdfFileContain3DModelFormat(path: path) {
//            return true
//        }
        
        return false
    }
    
    private func show3DPdf(path: String) {
        let message = "FILE_RENDER_PDF_INCLUDE_3D".localized
        let confirmStr = "FILE_RENDER_PDF_INCLUDE_3D_CONFIRM".localized
        let cancelStr = "FILE_RENDER_PDF_INCLUDE_3D_CANCEL".localized
        NSAlert.showAlert(withMessage: message, confirmButtonTitle: confirmStr, cancelButtonTitle: cancelStr) { (type) in
            if type == .sure {
                self.isSwitch = true
                self.delegate?.switch3D(oldController: self)
            } else {
                self.preview(path: path)
            }
        }
    }
    
}

extension NXNormalFileRenderWindowController:WebFrameLoadDelegate{
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!){
        waitingView?.isHidden = true

    }
}

extension NXNormalFileRenderWindowController:NSToolbarItemValidation {
    @discardableResult
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
       return item.isEnabled
    }
}

