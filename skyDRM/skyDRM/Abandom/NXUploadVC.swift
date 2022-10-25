//
//  NXUploadVC.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXUploadVCDelegate: NSObjectProtocol {
    func upload(files: [(src: String, dest:NXFileBase, originalFileName: String?, fileSource: NXFileBase?)])
    func uploadWithoutProtection(src: String, dest: NXFileBase)
}

class NXUploadVC: NSViewController {
    var srcFilePath: String? = nil
    var destFolder: NXFileBase? = nil
    
    weak var delegate: NXUploadVCDelegate?
    
    // check box
    @IBOutlet weak var checkPrint: NSButton!
    @IBOutlet weak var checkShare: NSButton!
    @IBOutlet weak var checkDownload: NSButton!
    @IBOutlet weak var checkOverlay: NSButton!
    
    @IBOutlet weak var nxlFileView: NSView!
    @IBOutlet weak var normalFileView: NSView!
    
    
    // label
    @IBOutlet weak var labelFileName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.refreshFileName()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        switchFileView()
        view.window?.styleMask = [.titled, .closable, .miniaturizable]
    }
    
    private func switchFileView() {
        
        guard let isNXLFile = NXLoginUser.sharedInstance.nxlClient?.isNXLFile(URL(fileURLWithPath: srcFilePath!)) else {
            return
        }
        
        if isNXLFile {
            nxlFileView.isHidden = false
            normalFileView.isHidden = true
        } else {
            nxlFileView.isHidden = true
            normalFileView.isHidden = false
        }
        
        adjustWindow(isNXLView: isNXLFile)
    }
    
    private func adjustWindow(isNXLView: Bool) {
        guard let window = view.window else {
            return
        }
        
        let newFrame: CGRect = {
            var newSize: CGSize
            if isNXLView {
                let nxlViewHeight: CGFloat = 172.0
                newSize = CGSize(width: window.frame.width, height: nxlViewHeight)
            } else {
                let normalViewHeight: CGFloat = 322.0
                newSize = CGSize(width: window.frame.width, height: normalViewHeight)
            }
            
            return CGRect(origin: window.frame.origin, size: newSize)
        }()
        
        
        window.setFrame(newFrame, display: true)
    }
    
    private func refreshFileName()
    {
        let fileName = URL(fileURLWithPath: srcFilePath!).lastPathComponent
        labelFileName.stringValue = fileName
    }
    
    private func protectFile(){
        // compose data
        
        // source file path
        let srcURL = URL(fileURLWithPath: srcFilePath!)
        
        // compose nxl file name with time stamp
        let fileName = NXCommonUtils.createNXLFileNameWithTimeStamp(originFileName: srcURL.lastPathComponent)
        
        // get temp folder
        let gitFolder = NXCommonUtils.getTempFolder()
        
        // temp file path
        let destURL = gitFolder?.appendingPathComponent(fileName, isDirectory: false)
        
        // assign rights
        let rights = NXLRights()
        rights.setRight(.NXLRIGHTVIEW, value: true)  // view rights was always set
        
        if (checkPrint.state == NSControl.StateValue.on){
            rights.setRight(.NXLRIGHTPRINT, value: true)
        }
        
        if (checkShare.state == NSControl.StateValue.on){
            rights.setRight(.NXLRIGHTSHARING, value: true)
        }
        
        if (checkDownload.state == NSControl.StateValue.on){
            rights.setRight(.NXLRIGHTSDOWNLOAD, value: true)
        }
        
        if (checkOverlay.state == NSControl.StateValue.on){
            rights.setObligation(.NXLOBLIGATIONWATERMARK, value: true)
        }
        
        // encrypt
        
        guard let sdkClient = NXLoginUser.sharedInstance.nxlClient else {
            return
        }
        
        let waitingView: NSView? = {
            if let contentView = NXCommonUtils.getMainWindow().contentView {
                return NXCommonUtils.createWaitingView(superView: contentView)
            }
            
            return nil
        }()
        
        
        sdkClient.encrypt(toNXLFile: srcURL, destPath: destURL, overwrite: true, permissions: rights, withCompletion: {(filePath, error) in
            DispatchQueue.main.async {
                waitingView?.removeFromSuperview()
            }
            
            Swift.print("encrypt result: \(String(describing: error))")
            if error != nil{  // failed, need error handling
                DispatchQueue.main.async {
                    NXToastWindow.sharedInstance?.toast(NSLocalizedString("UPLOAD_VIEW_ENCRYPT_FAILED", comment: ""))
                }
                
                NXCommonUtils.removeTempFileAndFolder(tempPath: destURL!)
            }else{                
                let myVaultService = NXBoundService()
                myVaultService.serviceType = ServiceType.kServiceMyVault.rawValue
                let myVaultRoot = NXFileBase()
                myVaultRoot.boundService = myVaultService
                myVaultRoot.fullServicePath = "/"
                
                let fileSource = NXFile()
                fileSource.localPath = srcURL.path
                fileSource.name = srcURL.lastPathComponent
                
                self.delegate?.upload(files: [(src: srcURL.path, dest: self.destFolder!, originalFileName: nil, fileSource: nil),
                                              (src: (destURL?.path)!, dest: myVaultRoot, originalFileName: srcURL.lastPathComponent, fileSource: fileSource)])
            }
        })
    }
    
    @IBAction func uploadWithoutProtection(_ sender: Any) {
        view.window?.close()
        
        self.delegate?.uploadWithoutProtection(src: srcFilePath!, dest: destFolder!)
    }
    
    @IBAction func uploadWithProtection(_ sender: Any) {
        view.window?.close()
        
        self.protectFile()
    }
    
    @IBAction func uploadNXLFile(_ sender: Any) {
        
        presentingViewController?.dismiss(self)
        
        self.delegate?.uploadWithoutProtection(src: srcFilePath!, dest: destFolder!)
    }
    
    @IBAction func browserFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                do {
                    if let filePath = openPanel.url?.path {
                        let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary?
                        if attr?.fileSize() == 0 {
                            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_UPLOAD_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                            })
                            return
                        }
                    }
                } catch {

                }
                
                let src = openPanel.url
                
                Swift.print("selected open file: \(String(describing: src))")
                
                
                self.srcFilePath = src?.path
                
                self.refreshFileName()
                
                self.switchFileView()
            }
        }
        
    }
}
