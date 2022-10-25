//
//  NXRepositoryViewController.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXRepositoryViewController: NSViewController, NXRepositoryActionDelegate {
    
    @IBOutlet weak var contentView: NSView!
    private var connectedView: NXConnectedRepositoryView!
    private var addView: NXAddRepositoryView!
    private var manageView: NXManageRepositoryView!
    weak var delegate: NXRepositoryVCDelegate!
    
    public enum MainView {
        case connected
        case add
        case manage(current: NXRMCRepoItem, all: [NXRMCRepoItem])
    }
    var mainView: MainView = .connected
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true;
        self.view.window?.styleMask = .titled
        switch mainView {
        case .connected:
            showConnectedView()
        case .add:
            showAddView()
        case .manage(let current, let all):
            showManageView()
            manageView.setRepoItem(repo: current, allRepo:all)
        }
    }
    
    //NXRepositoryActionDelegate
    func closeConnectedView() {
        onClose()
    }
    func closeAddView() {
        onClose()
    }
    func closeManageView() {
        onClose()
    }
    func gobackFromAddView() {
        showConnectedView()
    }
    func gobackFromManageView() {
        showConnectedView()
    }
    func openAddView() {
        showAddView()
    }
    func openManageView(currentRepo: NXRMCRepoItem,AllRepo:[NXRMCRepoItem]) {
        showManageView()
        manageView.setRepoItem(repo: currentRepo,allRepo:AllRepo)
    }
    func connect() {
        onClose()
    }
    func disconnect() {
        onClose()
    }
    func update() {
        onClose()
    }
    private func onClose() {
        removeAllViews()
        self.presentingViewController?.dismiss(self)
        if delegate != nil {
            delegate.onRepositoryVCClose()
        }
    }
    private func removeAllViews() {
        if connectedView != nil {
            connectedView.removeFromSuperview()
            connectedView = nil
        }
        if addView != nil {
            addView.removeFromSuperview()
            addView = nil
        }
        if manageView != nil {
            manageView.removeFromSuperview()
            manageView = nil
        }
    }
    private func showConnectedView() {
        removeAllViews()
        connectedView = NXCommonUtils.createViewFromXib(xibName: "NXConnectedRepositoryView", identifier: "connectedRepoView", frame: nil, superView: contentView) as? NXConnectedRepositoryView
        connectedView.delegate = self
    }
    private func showAddView() {
        removeAllViews()
        addView = NXCommonUtils.createViewFromXib(xibName: "NXAddRepositoryView", identifier: "addRepositoryView", frame: nil, superView: contentView) as? NXAddRepositoryView
        addView.delegate = self
    }
    private func showManageView() {
        removeAllViews()
        manageView = NXCommonUtils.createViewFromXib(xibName: "NXManageRepositoryView", identifier: "manageRepositoryView", frame: nil, superView: contentView) as? NXManageRepositoryView
        manageView.delegate = self
    }
}
