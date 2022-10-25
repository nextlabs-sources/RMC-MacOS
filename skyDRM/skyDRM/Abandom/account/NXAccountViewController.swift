//
//  NXAccountViewController.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXAccountViewController: NSViewController, NXAccountActionDelegate {
    
    @IBOutlet weak var contentView: NSView!
    private var logoutView: NXAccountLogoutView!
    private var changePwdView: NXChangePwdView!
    private var manageProfileView: NXManageProfileView!
    weak var delegate: NXAccountVCDelegate!
    
    public enum MainView {
        case logout
        case changePwd
        case manageProfile
    }
    var mainView: MainView = .logout
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true;
        self.view.window?.styleMask = .titled
        self.view.window?.backgroundColor = NSColor.white
        switch mainView {
        case .logout:
            showLogoutView()
        case .changePwd:
            showChangePwdView()
        case .manageProfile:
            showManageProfileView()
        }
    }
    
    //NXAccountActionDelegate
    func accountLogout() {
        removeAllViews()
        self.presentingViewController?.dismiss(self)
        if delegate != nil {
            delegate.onAccountLogout()
        }
    }
    func accountOpenChangeView() {
        showChangePwdView()
    }
    func accountCloseLogoutView() {
        onClose()
    }
    func accountChangeAvatar() {
        if delegate != nil {
            delegate.onAccountAvatar()
        }
    }
    func accountOpenManageView() {
        showManageProfileView()
    }
    func accountGobackFromChangeView() {
        showLogoutView()
    }
    func accountCloseChangeView() {
        onClose()
    }
    func accountGobackFromManageView() {
        showLogoutView()
    }
    func accountCloseManageView() {
        onClose()
    }
    func accountChangeName() {
        if delegate != nil {
            delegate.onAccountName()
        }
    }
    
    private func removeAllViews() {
        if logoutView != nil {
            logoutView.removeFromSuperview()
        }
        if changePwdView != nil {
            changePwdView.removeFromSuperview()
        }
        if manageProfileView != nil {
            manageProfileView.removeFromSuperview()
        }
    }
    private func showLogoutView() {
        removeAllViews()
        logoutView = NXCommonUtils.createViewFromXib(xibName: "NXAccountLogoutView", identifier: "accountLogoutView", frame: nil, superView: contentView) as? NXAccountLogoutView
        logoutView.delegate = self
    }
    private func showChangePwdView() {
        removeAllViews()
        changePwdView = NXCommonUtils.createViewFromXib(xibName: "NXChangePwdView", identifier: "changePwdView", frame: nil, superView: contentView) as? NXChangePwdView
        changePwdView.delegate = self
    }
    private func showManageProfileView() {
        removeAllViews()
        manageProfileView = NXCommonUtils.createViewFromXib(xibName: "NXManageProfileView", identifier: "manageProfileView", frame: nil, superView: contentView) as? NXManageProfileView
        manageProfileView.delegate = self
    }
    private func onClose() {
        removeAllViews()
        self.presentingViewController?.dismiss(self)
        if delegate != nil {
            delegate.onAccountVCClose()
        }
    }
}
