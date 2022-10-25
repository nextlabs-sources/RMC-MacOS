//
//  NXFileRenderWindowController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/9/14.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation
import SDML
protocol NXRenderWindowControllerDelegate: NSObjectProtocol {
    func close(windowController: NSWindowController)
    func switch3D(oldController: NXFileRenderWindowController)
}

 class NXFileRenderWindowController: NSWindowController {
    
    weak var delegate: NXRenderWindowControllerDelegate?
    var fileItem: NXFileBase?
    var renderEventSrcType: NXCommonUtils.renderEventSrcType?
    
    var waitingView: NXWaitingView?
    var nxRenderProxy = NXFileRenderProxy()
    
    var isSwitch = false
    func commonInit(fileItem: NXFileBase, renderEventSrcType: NXCommonUtils.renderEventSrcType) {
        self.fileItem = fileItem
        self.renderEventSrcType = renderEventSrcType
        
        waitingView?.isHidden = false

        self.nxRenderProxy.delegate = self
        self.nxRenderProxy.parseFile(file: fileItem, type: renderEventSrcType)
        
    }
    
    func commonInit(fileItem: NXFileBase, renderEventSrcType: NXCommonUtils.renderEventSrcType, decryptProxy: NXFileRenderProxy) {
        self.fileItem = fileItem
        self.renderEventSrcType = renderEventSrcType
        self.nxRenderProxy = decryptProxy
        
        if let _ = fileItem as? NXNXLFile {
            self.parseFileFinish(path: decryptProxy.nxFileItem.tempFilePath!, error: nil)
        } else {
            self.parseFileFinish(path: fileItem.localPath, error: nil)
        }
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        waitingView = NXCommonUtils.createWaitingView(superView: (self.window?.contentView!)!)
        waitingView?.isHidden = true
    }
    
    
    func share() {
        if fileItem?.size == 0 {
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
            })
            return
        }
        
        guard let file = fileItem as? NXNXLFile else {
            return
        }
        
        let vc = NXHomeShareVC()
        vc.delegate = self
        vc.mainViewType = .configure
        vc.shareConfigFile = file
        self.contentViewController?.presentAsModalWindow(vc)
    }
    func addNXLToProject() {
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            if (fileItem?.sdmlBaseFile as? SDMLProjectFile) != nil {
                vc.addFileToProject(file: fileItem as! NXProjectFileModel)
            } else {
                NXClient.getCurrentClient().getRight(path: fileItem?.localPath ?? "") { [weak self](value, error) in
                    if let tags = value?.tags {
                        DispatchQueue.main.async {
                            vc.addFileToProjectWith(path: self?.fileItem?.localPath ?? "", tags: tags)
                        }
                    }
                }
            }
        }
    }
  
    func protect(filePath: String) {
        let url = URL(fileURLWithPath: filePath)
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
                vc.protectFile(urls: [url])
        }
    }
    func protectAndShare(filePath: String) {
        let url = URL(fileURLWithPath: filePath)
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            vc.shareFile(urls: [url])
        }
    }
    
    func showFileInfo() {
        let viewController = FileInfoViewController()
        guard let nxlFile = fileItem as? NXNXLFile else {
            return
        }
        
        if nxlFile.rights == nil {
            if let rightOb = nxRenderProxy.nxFileItem.rightOb {
                nxlFile.rights = rightOb.rights
                nxlFile.watermark = rightOb.watermark
                nxlFile.expiry = rightOb.expiry
            }
            if let isTag = nxRenderProxy.nxFileItem.isTag, let tags = nxRenderProxy.nxFileItem.tags {
                nxlFile.isTagFile = isTag
                nxlFile.tags = tags
            }
            
            if let isOwner = nxRenderProxy.nxFileItem.isSteward {
                nxlFile.isOwner = isOwner
            }
        }
            
        viewController.file = nxlFile
        
        self.contentViewController?.presentAsModalWindow(viewController)
    }
}

extension NXFileRenderWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification){
        delegate?.close(windowController: self)
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        if let _ = self.window?.attachedSheet {
            NXMainMenuHelper.shared.onModalSheetWindow()
        }
        else {
            NXMainMenuHelper.shared.onFileRenderWindow()
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let _ = self.window?.attachedSheet {
            NXMainMenuHelper.shared.onModalSheetWindow()
        }
        else {
            NXMainMenuHelper.shared.onFileRenderWindow()
        }
    }
    
    func windowDidResignMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    
    func windowDidResize(_ notification: Notification) {
    }
}

extension NXFileRenderWindowController: NXFileRenderDelegate {
    func startParse(){
        waitingView?.isHidden = false
    }
    
  @objc  func parseFileFinish(path: String, error: NSError?) {
    DispatchQueue.main.async {
        self.waitingView?.isHidden = true
    }
   
        if error != nil {
            self.window?.close()
            return
        }
        
        if fileItem?.size == 0 {
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_OPEN_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
            })
        }
    }
}

extension NXFileRenderWindowController: NXHomeShareVCDelegate {
    func shareFinish(isNewCreated: Bool, files: [NXNXLFile]) {
        // Update file list.
        guard let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController else {
            return
        }
        
        switch vc.clickType! {
        case .myVault:
            vc.myVaultViewController.refresh()
        case .outBox:
            vc.fileListViewController.refresh()
        default:
            break
        }
    }
}
