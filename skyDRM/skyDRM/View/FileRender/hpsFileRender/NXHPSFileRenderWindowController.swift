//
//  NXHPSFileRenderWindowController.swift
//  skyDRM
//
//  Created by helpdesk on 3/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import SDML

let renderHPSNotification = Notification.Name("renderHPSNotification")

class NXHPSFileRenderWindowController: NXFileRenderWindowController {
    
    @IBOutlet var shareItem: NSToolbarItem!
    @IBOutlet var printItem: NSToolbarItem!
    @IBOutlet var propertyItem: NSToolbarItem!
    @IBOutlet var toolbar: NSToolbar!
    
    @IBOutlet var targetVC: NSViewController!
    fileprivate var renderFilePath: String?
    private var canAddFileToProject = false
    
    class func loadFromNib() -> NXHPSFileRenderWindowController{
        let windowController = NXHPSFileRenderWindowController()
        windowController.window?.delegate = windowController
        return windowController
    }
    
    override var windowNibName: NSNib.Name? {
    return NSNib.Name("NXHPSFileRenderWindowController")
    }

    deinit {
        waitingView?.removeFromSuperview()
        if self.nxRenderProxy.nxFileItem.autoDelete == true,
            let tempPath = self.nxRenderProxy.nxFileItem.tempFilePath {
            NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: tempPath))
        }
        
        debugPrint(#function + self.className)
        NotificationCenter.default.removeObserver(self)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(catchNotification), name: NSNotification.Name(rawValue: "hpsProgressNotification"), object: nil)
        location()
        self.contentViewController = targetVC
    }

    @objc func catchNotification(notification: Notification) {
        if notification.name == NSNotification.Name(rawValue: "hpsProgressNotification") {
            if let localPath = notification.userInfo?["local_path"] as? String{
                if localPath == renderFilePath{
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "hpsProgressNotification"), object: nil)
                    
                    if let status = notification.userInfo?["status"] as? String {
                        if status == "success"{
                            self.updateToolbarItem()
                        } else {
                            let message = NSLocalizedString("FILE_RENDER_FAILED", comment: "")
                            NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: { (type) in
                                self.window?.close()
                            })
                        }
                    }
                }
            }
        }         
    }
    
    fileprivate func renderFile(filePath path:String){
        renderFilePath = path
        waitingView?.isHidden = true
        objc_setAssociatedObject(self.window?.contentView as Any, NXHPSViewKey, path, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        NotificationCenter.default.post(name:renderHPSNotification, object: nil, userInfo: ["message":path, "date":Date()])
        
        afterOpenedFile()
    }
    
    fileprivate func afterOpenedFile(){
        updateToolbarItem()
        self.validateToolbarItem(shareItem)
        self.validateToolbarItem(printItem)
        addOverlay()
    }
    
    func addOverlay() {
        guard let watermarkText = self.nxRenderProxy.nxFileItem.rightOb?.watermark else {
            return
        }
        
        let overlayInfo = NXOverlayInfo(text: watermarkText.text)
        let watermark = NXWatermark(overlayInfo: overlayInfo)
        let overlayView = NXOverlayView(watermark:watermark)
        
        overlayView.frame = (self.window?.contentView?.bounds)!
        self.window?.contentView?.addSubview(overlayView)
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0))
        
        self.window?.contentView!.addConstraint(NSLayoutConstraint(item: overlayView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.window?.contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
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
    
    @IBAction func onFileInfoClick(_ sender: Any) {
        if !(self.fileItem is NXNXLFile) {
            super.protectAndShare(filePath: fileItem?.localPath ?? "")
            return
        }
        
        super.showFileInfo()
    }
    
    @IBAction func onPrintClick(_ sender: Any) {
        if let file = self.fileItem {
            NXCommonUtils.addLog(file: file, operation: "Print", isAllow: true)
        }
        
        let v = self.window?.contentView
        let sEx = v?.window?.convertToScreen((v?.frame)!)
        
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
        picPrint.runModal(for: self.window!, delegate: nil, didRun: nil, contextInfo: nil)
    }
    
    override func parseFileFinish(path: String, error: NSError?) {
        super.parseFileFinish(path: path, error: error)
        
        if error != nil {
            return
        }
        
        if NXFileRenderSupportUtil.shouldConvert(filePath: path) {
            waitingView?.isHidden = false
            let folder = NXCommonUtils.getConvertFileFolder()?.path
            NXClient.getCurrentClient().convertFile(path: path, toFormat: "hsf", toFolder: folder!, isOverwrite: true) { (destPath, error) in
                self.waitingView?.isHidden = true
                guard let destPath = destPath else {
                    NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
                    NSAlert.showAlert(withMessage: NSLocalizedString("FILE_RENDER_RENDER_FILECONTENTS_ERROR", comment: ""), informativeText: "", dismissClosure: { (type) in
                        self.window?.close()
                    })
                    return
                }
                
                NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: path))
                self.nxRenderProxy.nxFileItem.tempFilePath = destPath
                self.renderFile(filePath: destPath)
            }
            
        } else {
            self.renderFile(filePath: path)
        }
    }
}

extension NXHPSFileRenderWindowController:NSToolbarItemValidation {
    @discardableResult
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return item.isEnabled
    }
}
