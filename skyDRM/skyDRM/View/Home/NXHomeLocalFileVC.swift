//
//  NXHomeLocalFileVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXHomeLocalFileVC: NSViewController {

    @IBOutlet weak var contentView: NSView!
    fileprivate var mainView: NXHomeLocalFileMainView?
    fileprivate var protectView: NXHomeProtectConfigureView?
    fileprivate var shareView: NXHomeShareConfigureView?
    fileprivate var protectResultView: NXHomeProtectResultView?
    fileprivate var shareResultView: NXHomeShareResultView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true;
        self.view.window?.styleMask = .titled
        self.view.window?.backgroundColor = NSColor.white
        showMainView()
    }
    
    private func removeAllView() {
        mainView?.removeFromSuperview()
        protectView?.removeFromSuperview()
        shareView?.removeFromSuperview()
        protectResultView?.removeFromSuperview()
        shareResultView?.removeFromSuperview()
    }
    fileprivate func showMainView() {
        removeAllView()
        mainView = NXCommonUtils.createViewFromXib(xibName: "NXHomeLocalFileMainView", identifier: "homeLocalFileMainView", frame: nil, superView: contentView) as? NXHomeLocalFileMainView
        mainView?.delegate = self
    }
    fileprivate func showProtectView() {
        removeAllView()
        protectView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectConfigureView", identifier: "homeProtectConfigureView", frame: nil, superView: contentView) as? NXHomeProtectConfigureView
    }
    fileprivate func showShareView() {
        removeAllView()
        shareView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareConfigureView", identifier: "homeShareConfigureView", frame: nil, superView: contentView) as? NXHomeShareConfigureView
    }
    fileprivate func showProtectResultView() {
        removeAllView()
        protectResultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeProtectResultView", identifier: "homeProtectResultView", frame: nil, superView: contentView) as? NXHomeProtectResultView
    }
    fileprivate func showShareResultVie() {
        removeAllView()
        shareResultView = NXCommonUtils.createViewFromXib(xibName: "NXHomeShareResultView", identifier: "homeShareResultView", frame: nil, superView: contentView) as? NXHomeShareResultView
    }
}

extension NXHomeLocalFileVC: NXHomeLocalFileMainViewDelegate {
    func onProtect(url: URL) {
        DispatchQueue.main.async {
            self.showProtectView()
            let _: NXSelectedFile = .localFile(url: url)
        }
    }
    func onShare(url: URL) {
        DispatchQueue.main.async {
            self.showShareView()
        }
    }
}
