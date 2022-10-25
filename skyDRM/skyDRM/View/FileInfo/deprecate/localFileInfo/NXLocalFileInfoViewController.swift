//
//  NXLocalFileInfoViewController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/26/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol FileInfoViewControllerDelegate: class {
    func close()
}

class NXLocalFileInfoViewController: NSViewController {
    fileprivate struct Constant{
        static let rightsViewControllerXibName = "NXLocalRightsViewController"
        static let fileInfoActionViewControllerXibName = "NXLocalFileInfoActionViewController"
        static let defaultInterval: CGFloat = 8
        
        static let normalInfoViewControllerXibName = "NXLocalNormalFileInfoViewController"
    }
    
    @IBOutlet weak var fileInfoView: NSView!
    @IBOutlet weak var rightsView: NSView!
    
    var file: NXFileBase!
    var fileRenderItem:NXFileRenderItem? = nil
    var parentWindow:NSWindow?
    weak var delegate: FileInfoViewControllerDelegate?
    
    fileprivate var downloadOrUploadId:Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        parentWindow = NSApplication.shared.keyWindow
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        adjustWindowPosition()
        
        settingFileInfo()
        
        rightsView.wantsLayer = true
        rightsView.layer?.backgroundColor = NSColor.white.cgColor
        
        addMaskView()
        addCustomView()
    }
    
    
    @IBAction func close(_ sender: Any) {
        closeWindow()
    }
    
    func closeWindow(){
        self.presentingViewController?.dismiss(self)
        removeMaskView()
    }
    
    private func settingFileInfo(){
        let infoViewController: NSViewController? = {
            let infoViewController = NXLocalNormalFileInfoViewController(nibName:  Constant.normalInfoViewControllerXibName, bundle: nil)
            
            infoViewController.file = file

            infoViewController.delegate = self
            
            return infoViewController
        }()
        
        if let viewController = infoViewController{
            addChild(viewController)
            
            viewController.view.frame = fileInfoView.bounds
            fileInfoView.addSubview(viewController.view)
        }
    }
    
    func addMaskView(){
        if let contentView = parentWindow?.contentView{
            contentView.addSubview(MaskView.sharedInstance)
        }
    }
    
    func removeMaskView(){
        MaskView.sharedInstance.removeFromSuperview()
    }
    
    func isNXLFile()->Bool{        
        let fileURL = URL(fileURLWithPath: file.localPath)
        
        
        if (NXClient.isNXLFile(path:fileURL.path)){
            return true
        }else{
            return false
        }
    }
    
    func addCustomView(){
        if isNXLFile(){
            addRightsView()
        }else{
            addFileActionView()
        }
    }
    
    func addRightsView(){
        let rightsViewController = NXLocalRightsViewController(nibName: Constant.rightsViewControllerXibName, bundle: nil)
        let viewController = rightsViewController

        
        viewController.view.frame = rightsView.bounds
        rightsView.addSubview(viewController.view)
        addChild(viewController)
        
        NXLoginUser.sharedInstance.nxlClient?.getNXLFileRights(URL(fileURLWithPath: file.localPath)) { (rights, isSteward, error) in
            
            DispatchQueue.main.async {
                for child in self.children {
                    if let rightsViewController = child as? NXLocalRightsViewController {
                        var fileRights: [NXRightType]?
                        if let rights = rights {
                            fileRights = NXCommonUtils.convertNXLRightsToFileRight(rights: rights)
                        }
                        rightsViewController.rights = fileRights
                    }
                }
                
                if error != nil {
                    if (error as NSError?)?.code == 403 {
                        viewController.textLabelValue = NSLocalizedString("FILE_LOCAL_INFO_NO_RIGHTS", comment: "")
                    } else {
                        viewController.textLabelValue = NSLocalizedString("FILE_LOCAL_INFO_GET_RIGHTS_FAILED", comment: "")
                    }
                } else {
                    if isSteward{
                        viewController.textLabelValue = NSLocalizedString("FILE_LOCAL_INFO_STEWARD_RIGHTS", comment: "")
                    }else{
                        if rights?.getRights() != 0 {
                            viewController.textLabelValue = NSLocalizedString("FILE_LOCAL_INFO_NOT_STEWARD_RIGHTS", comment: "")
                        } else {
                            viewController.textLabelValue = NSLocalizedString("FILE_LOCAL_INFO_NO_RIGHTS", comment: "")
                        }
                    }
                }
            }
            
        }
    }
    
    func addFileActionView(){
        let fileInfoActionViewController = NXLocalFileInfoActionViewController(nibName:  Constant.fileInfoActionViewControllerXibName, bundle: nil)
        let viewController = fileInfoActionViewController
        
        viewController.file = file
        viewController.delegate = self
        viewController.view.frame = rightsView.bounds
        rightsView.addSubview(viewController.view)
        addChild(viewController)
    }
    
    private func adjustWindowPosition(){
        guard let currentWindow = view.window else{
            return
        }
        
        if let parentWindow = parentWindow{
            let x = (parentWindow.frame.width - currentWindow.frame.width)/2
            let y = (parentWindow.frame.height - currentWindow.frame.height)/2
            
            currentWindow.setFrameOrigin(CGPoint(x: parentWindow.frame.origin.x + x, y: parentWindow.frame.origin.y + y))
        }
        
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.styleMask = .titled
    }
}
extension NXLocalFileInfoViewController: NXLocalFileInfoActionViewControllerDelegate{
    func protect() {
        closeWindow()
    }
    
    func share(){
        closeWindow()
    }
}
