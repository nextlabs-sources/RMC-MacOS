//
//  NXManageMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXManageMenuAction: NSObject {
    static let shared = NXManageMenuAction()
    private var repositoryArrayContext = 0
    override private init() {
        super.init()
        NXLoginUser.sharedInstance.addObserver(self, forKeyPath: "repositoryArray", options: .new, context: &repositoryArrayContext)
    }
    deinit {
        NXLoginUser.sharedInstance.removeObserver(self, forKeyPath: "repositoryArray", context: &repositoryArrayContext)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &repositoryArrayContext {
            refreshRepositories()
        }
        else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
  @objc  func search() {
        guard let contentVC = NSApplication.shared.mainWindow?.contentViewController else {
            return
        }
        if let vc = contentVC as? ViewController {
            guard let fileListView = vc.fileListView else {
                return
            }
            fileListView.focusSearchField()
        }
        else if let projectvc = contentVC as? NXSpecificProjectViewController {
            if projectvc.contentSubView is NXSpecificProjectFilesView,
                let fileView = projectvc.filesView {
                fileView.focusSearchField()
            }
            else if projectvc.contentSubView is NXProjectMemberView,
                let peopleView = projectvc.peoplesView {
                peopleView.focusSearchField()
            }
        }
    }
 @objc   func addRepository() {
        let repoVC = NXRepositoryViewController()
        repoVC.mainView = .add
    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(repoVC)
    }
 @objc   func repositories() {
    }
  @objc  func openLocalfile() {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
            return
        }
        let localFileVC = NXHomeLocalFileVC()
    vc.presentAsModalWindow(localFileVC)
    }
  @objc  func profile() {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
        return
        }
        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
            return
        }
        vc.navButtonClicked(index: 1001)
    }
 @objc   func account() {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
            return
        }
        vc.navButtonClicked(index: 1000)
    }
  @objc  func usage() {
        print("usage")
    }
    @objc func preferences() {
        print("preferences")
    }
    private func refreshRepositories() {
        let repositoriesMenu: NXManageMenu = .repositories
        let subMenu = repositoriesMenu.submenu
        subMenu?.removeAllItems()
        
        let repositories = NXLoginUser.sharedInstance.repository()
        for repository in repositories {
            let newItem = createRepositoryItem(title: repository.name)
            subMenu?.addItem(newItem)
        }
        
        let repos = NXLoginUser.sharedInstance.repository()
        if repos.count == 0 {
            repositoriesMenu.menuItem?.isEnabled = false
        }
        else {
            repositoriesMenu.menuItem?.isEnabled = true
        }
    }
    private func createRepositoryItem(title: String) -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = title
        let menu = NSMenu()
        menu.autoenablesItems = false
        menuItem.submenu = menu
        let viewItem = NSMenuItem(title: NSLocalizedString("MENU_MANAGE_REPOSITORIES_VIEW_FILES", comment: ""), action: #selector(NXManageMenuAction.viewRepository(sender:)), keyEquivalent: "")
        viewItem.target = self
        let renameItem = NSMenuItem(title: NSLocalizedString("MENU_MANAGE_REPOSITORIES_RENAME", comment: ""), action: #selector(NXManageMenuAction.renameRepository(sender:)), keyEquivalent: "")
        renameItem.target = self
        let removeItem = NSMenuItem(title: NSLocalizedString("MENU_MANAGE_REPOSITORIES_REMOVE", comment: ""), action: #selector(NXManageMenuAction.renameRepository(sender:)), keyEquivalent: "")
        removeItem.target = self
        menu.addItem(viewItem)
        menu.addItem(renameItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(removeItem)
        return menuItem
    }
    
    @objc  public func viewRepository(sender: NSMenuItem) {
        guard let parentItem = sender.parent else {
            return
        }
        let repositories = NXLoginUser.sharedInstance.repository()
        for repository in repositories {
            if repository.name == parentItem.title {
                guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
                    return
                }
                guard let vc = delegate.mainWindow?.contentViewController as? ViewController else {
                    return
                }
                vc.homeGotoMySpace(type: .cloudDrive, alias: repository.name)
                return
            }
        }
    }
    @objc  public func renameRepository(sender: NSMenuItem) {
        guard let parentItem = sender.parent else {
            return
        }
        let repositories = NXLoginUser.sharedInstance.repository()
        for repository in repositories {
            if repository.name == parentItem.title {
                let repoVC = NXRepositoryViewController()
                repoVC.mainView = .manage(current: repository, all: repositories)
                NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(repoVC)
                return
            }
        }
    }
    public func removeRepository(sender: NSMenuItem) {
        guard let parentItem = sender.parent else {
            return
        }
        let repositories = NXLoginUser.sharedInstance.repository()
        for repository in repositories {
            if repository.name == parentItem.title {
                let repoVC = NXRepositoryViewController()
                repoVC.mainView = .manage(current: repository, all: repositories)
                NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(repoVC)
                return
            }
        }
    }
}
