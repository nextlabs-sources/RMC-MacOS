//
//  NXHomeShareVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeShareVCDelegate: NSObjectProtocol {
    func shareFinish(isNewCreated: Bool, files: [NXNXLFile])
}

class NXHomeShareVC: NSViewController {
    
    weak var delegate: NXHomeShareVCDelegate?
    
    @IBOutlet weak var contentView: NSView!
//    fileprivate var mainView: NXHomeShareMainView?
    fileprivate var createView: NXHomeProtectConfigureView?//NXHomeShareCreateView?
    fileprivate var configureView: NXHomeShareConfigureView?
    fileprivate var resultView: NXHomeShareResultView?
    
    public enum MainViewType {
        case selectFile
        case create
        case configure
        case result
    }
    public var mainViewType: MainViewType = .create
    public var selectedFile: [NXSelectedFile]? {
        didSet {
            if let selectedFile = selectedFile {
                createView?.selectedFile = selectedFile
            }
        }
    }
    
    var shareConfigFile: NXNXLFile?
    
    var isNewCreated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    override func viewWillAppear() {
        switch mainViewType {
        case .selectFile:
//            showMainView()
            break
        case .create:
            showCreateView()
        case .configure:
            showConfigureView()
        case .result:
            showResultView()
        }
        adjustWindowPosition(with: NXCommonUtils.getMainWindow())
        
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: 490))
        }
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
    
    private func removeAllView() {
//        mainView?.removeFromSuperview()
        createView?.removeFromSuperview()
        configureView?.removeFromSuperview()
        resultView?.removeFromSuperview()
        
    }
//    fileprivate func showMainView() {
//        removeAllView()
//        mainView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareMainView", identifier: "homeShareMainView", frame: nil, superView: contentView) as? NXHomeShareMainView
//        mainView?.delegate = self
//    }
    fileprivate func showCreateView() {
        removeAllView()
        createView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectConfigureView", identifier: "homeProtectConfigureView", frame: nil, superView: contentView) as? NXHomeProtectConfigureView
        createView?.delegate = self
        createView?.protectType = .myVaultShared
        if let selectedFile = selectedFile {
            createView?.selectedFile = selectedFile
        }
    }
    fileprivate func showConfigureView() {
        removeAllView()
        configureView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareConfigureView", identifier: "homeShareConfigureView", frame: nil, superView: contentView) as? NXHomeShareConfigureView
        configureView?.delegate = self
        if let file = shareConfigFile {
            configureView?.selectedFile = [file]
            let right = NXRightObligation()
            right.rights = file.rights!
            right.watermark = file.watermark
            right.expiry = file.expiry
            if file.rights!.contains(.watermark) == false && file.watermark != nil {
               right.rights.append(.watermark)
            }
            
            configureView?.right = right
        }
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 650, height: 550))
        }
        
    }
    fileprivate func showResultView() {
        removeAllView()
        resultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareResultView", identifier: "homeShareResultView", frame: nil, superView: contentView) as? NXHomeShareResultView
        resultView?.delegate = self
        if let window = self.view.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 650, height: 550))
        }
    }
    
    func close(files: [NXNXLFile]) {
        delegate?.shareFinish(isNewCreated: isNewCreated, files: files)
        self.presentingViewController?.dismiss(self)
    }
}

//extension NXHomeShareVC: NXHomeShareMainViewDelegate {
//    func onShare(info: NXSelectedFile) {
//    }
//}

extension NXHomeShareVC: NXHomeProtectConfigureViewDelegate {
    func nextCreateProjectFile(selectedFile: [NXSelectedFile], tags: [String : [String]], destPath: String, type: NXProtectType?, right: NXRightObligation) {
    }
    

    func protectFinish(files: [NXNXLFile], right: NXRightObligation?, tags: [String: [String]]?, destPath: String?, type: NXProtectType?) {
        if type == .myVaultShared {
            self.isNewCreated = true
            DispatchQueue.main.async {
                self.mainViewType = .configure
                self.showConfigureView()
                self.configureView?.selectedFile = files
                self.configureView?.right = right
            }
        }
    }
    
    func nextCreateProtectedAndSharedNXLFile(selectedFile:[NXSelectedFile], right: NXRightObligation?, tags: [String: [String]]?,destPath: String?, type: NXProtectType?)
    {
        if type == .myVaultShared {
            self.isNewCreated = true
            DispatchQueue.main.async {
                self.mainViewType = .configure
                self.showConfigureView()
                self.configureView?.selectedFileReadyForProtectAndShare = selectedFile
                self.configureView?.right = right
                self.configureView?.isNeedProtectFirst = true
            }
        }
    }

    func onProtectFailed() {
        close(files: [])
    }
}

extension NXHomeShareVC: NXHomeShareConfigureViewDelegate {
    func onShareFinish(files: [NXNXLFile], right: NXRightObligation, emails: [String], comments: String) {
        DispatchQueue.main.async {
            self.mainViewType = .result
            self.showResultView()
            self.resultView?.files = files
            self.resultView?.emails = emails
            self.resultView?.rights = right
            self.resultView?.comments = comments
        }
        
    }

    func onShareFailed() {

    }
    
    func closeShareConfigure(files: [NXNXLFile]) {
        close(files: files)
    }
    
    func onTapCancelShareButton()
    {
        self.presentingViewController?.dismiss(self)
    }
}

extension NXHomeShareVC: NXHomeShareResultViewDelegate {
    func closeShareResult(files: [NXNXLFile]) {
        close(files: files)
    }
}

extension NXHomeShareVC: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        switch mainViewType {
        case .configure:
            if let files = configureView?.selectedFile {
                close(files: files)
            }
        case .result:
            if let files = resultView?.files {
                close(files: files)
            }
        default:
            break
        }
    }
}
