//
//  NXCheckPermissionViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 02/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXCheckPermissionViewControllerDelegate: NSObjectProtocol {
    func close(with file: NXFileBase?)
}

class NXCheckPermissionViewController: NSViewController {
    
    fileprivate struct Constant {
        // Display Message
        static let getRightsErrorMessage = NSLocalizedString("PERMISSION_GET_RIGHTS_ERROR", comment: "")
        static let encryptSuccessMessage = NSLocalizedString("PERMISSION_ENCRYPT_SUCCESS", comment: "")
        static let encryptErrorMessage = NSLocalizedString("PERMISSION_ENCRYPT_ERROR", comment: "")
        static let decryptSuccessMessage = NSLocalizedString("PERMISSION_DECRYPT_SUCCESS", comment: "")
        static let decryptErrorMessage = NSLocalizedString("PERMISSION_DECRYPT_ERROR", comment: "")
        static let stewardText = NSLocalizedString("PERMISSION_STEWARD_TEXT", comment: "")
        static let notStewardText = NSLocalizedString("PERMISSION_NOT_STEWARD_TEXT", comment: "")
        static let noRightsText = NSLocalizedString("PERMISSION_NO_RIGHTS_TEXT", comment: "")
        static let errorText = NSLocalizedString("PERMISSION_ERROR_TEXT", comment: "")
    }
    
    // Input
    var file: NXFileBase!
    weak var delegate: NXCheckPermissionViewControllerDelegate?
    
    // View
    @IBOutlet weak var topView: NSView!
    @IBOutlet weak var bottomView: NSView!
    
    var waitingView: NXWaitingView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        bottomView.wantsLayer = true
        bottomView.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        addCustomView()
    }
    
    @IBAction func close(_ sender: Any) {
        close()
    }
    
    fileprivate func close(){
        delegate?.close(with: file)
    }
    
    private func addFileInfoView() {
        
        let infoViewController = NXLocalNormalFileInfoViewController()
        infoViewController.file = file
        infoViewController.delegate = self
        infoViewController.view.frame = topView.bounds
        topView.addSubview(infoViewController.view)
        addChild(infoViewController)
        
        NXLoginUser.sharedInstance.nxlClient?.getNXLFileRights(URL(fileURLWithPath: file.localPath)) {
            (rights, isSteward, error) in
            var fileRights: [NXRightType]?
            if let rights = rights {
                fileRights = NXCommonUtils.convertNXLRightsToFileRight(rights: rights)
            }
            
            DispatchQueue.main.async {
                if isSteward || (fileRights?.contains(.share) == true) {
                    infoViewController.share.isEnabled = true
                } else {
                    infoViewController.share.isEnabled = false
                }
            }
        }
    }
    
    private func addCustomView(){
        
        // top view
        addFileInfoView()
        
        // bottom view
        if isNXLFile(with: file.localPath) {
            addRightsView()
        }else{
            addFileActionView()
        }
    }
    
    private func addRightsView(){
        let rightsViewController = NXLocalRightsViewController()
        rightsViewController.view.frame = bottomView.bounds
        bottomView.addSubview(rightsViewController.view)
        addChild(rightsViewController)
        
        NXLoginUser.sharedInstance.nxlClient?.getNXLFileRights(URL(fileURLWithPath: file.localPath)) {
            (rights, isSteward, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    if (error as NSError?)?.code == 403 {
                        rightsViewController.textLabelValue = Constant.noRightsText
                    } else {
                        rightsViewController.textLabelValue = Constant.errorText
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                
                var fileRights: [NXRightType]?
                if let rights = rights {
                    fileRights = NXCommonUtils.convertNXLRightsToFileRight(rights: rights)
                }
                rightsViewController.rights = fileRights
                
                if isSteward{
                    rightsViewController.textLabelValue = Constant.stewardText
                }else{
                    if rights?.getRights() != 0 {
                        rightsViewController.textLabelValue = Constant.notStewardText
                    } else {
                        rightsViewController.textLabelValue = Constant.noRightsText
                    }
                }
            }
            
        }
    }
    
    private func addFileActionView(){
        let fileInfoActionViewController = NXLocalFileInfoActionViewController()
        
        fileInfoActionViewController.file = file
        fileInfoActionViewController.delegate = self
        fileInfoActionViewController.view.frame = bottomView.bounds
        bottomView.addSubview(fileInfoActionViewController.view)
        addChild(fileInfoActionViewController)
    }
    
}

/// Tool
extension NXCheckPermissionViewController {
    fileprivate func isNXLFile(with localPath: String) -> Bool {
        let url = URL(fileURLWithPath: localPath)
        
        let isNXLFile = (NXLoginUser.sharedInstance.nxlClient?.isNXLFile(url) == true) ? true: false
        
        return isNXLFile
    }
    
    fileprivate func shareFile(with file: NXFileBase) {
        let viewController = NXProtectViewController()
        viewController.file = file
        viewController.fileProtectType = NXFileProtectType.share
        
        self.view.addSubview(MaskView.sharedInstance)
        self.presentAsModalWindow(viewController)
        viewController.doWork()
    }
    
    func protectFile(with file: NXFileBase) {
        let viewController = NXProtectViewController()
        viewController.file = file
        viewController.fileProtectType = NXFileProtectType.protect
        
        self.view.addSubview(MaskView.sharedInstance)
        self.presentAsModalWindow(viewController)
        viewController.doWork()
    }
}

extension NXCheckPermissionViewController: NXLocalFileInfoActionViewControllerDelegate {
    func protect() {
        protectFile(with: file)
    }
    
    func share() {
        shareFile(with: file)
    }
}
