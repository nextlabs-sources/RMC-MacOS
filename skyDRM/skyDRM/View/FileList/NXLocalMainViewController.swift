//
//  NXLocalMainViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 17/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import Alamofire
class NXLocalMainViewController: NSViewController {

    struct Constant {
        static let kOperationIdentifer = "NXLocalMainOperationViewController"
        static let kFooterIdentifer = "NXLocalMainFooterViewController"
        static let kFileListNibName = "NXLocalMainFileListViewController"
        static let kSiderBarNibName = "NXSiderBarViewController"
        static let kMyvaultListNibName = "NXMyVaultViewController"
        static let kProjectTabViewNibName = "NXProjectTabViewController"
        static let kProjecFilesNibName = "NXProjectFileViewController"
        static let kProjectNomalFileSNibName = "NXProjectNormalFileViewContrller"
        
        static let kBaseFileViewController = "NXBaseFileViewController"
        
        static let minWindowSize = NSSize(width: 1200, height: 600)
    }
    
    @IBOutlet weak var operationView: NSView!
    @IBOutlet weak var footerView: NSView!
    @IBOutlet weak var fileListView: NSView!
    @IBOutlet weak var siderBarView: NSView!
    var preViewControllr: NSViewController!
    var nowSelected:Int = 0
    var clickType: selectecType?
    var operationViewController: NXLocalMainOperationViewController!
    var fileListViewController: NXLocalMainFileListViewController!
    var footerViewController: NXLocalMainFooterViewController!
    var siderBarViewController:NXSiderBarViewController!
    var isFirstOpen = true
    lazy var myVaultViewController:NXMyVaultViewController = {
        let myVaultViewController = NXMyVaultViewController(nibName:  Constant.kMyvaultListNibName, bundle: nil)
        myVaultViewController.view.frame = self.fileListView.bounds
        myVaultViewController.addObserver(self, forKeyPath: "displayData", context: nil)

        isMyVaultViewInit = true
        
        return myVaultViewController
    }()
    
    lazy var offlineViewController: NXOfflineFilesVC = {
        let offlineVC = NXOfflineFilesVC(nibName: Constant.kMyvaultListNibName, bundle: nil)
        offlineVC.view.frame = self.fileListView.bounds
        offlineVC.addObserver(self, forKeyPath: "displayData", context: nil)
        offlineVC.delegate = self
        
        isOfflineViewInit = true
        
        return offlineVC
    }()
    
    lazy var sharedWithMeVC: NXSharedWithMeVC = {
        let sharedVC = NXSharedWithMeVC(nibName:  Constant.kMyvaultListNibName, bundle: nil)
        sharedVC.view.frame = self.fileListView.bounds
        sharedVC.addObserver(self, forKeyPath: "displayData", context: nil)
        
        isShareWithMeViewInit = true
        
        return sharedVC
    }()
    lazy var projectFileVC:NXProjectFileViewController = {
        let projectFileVC = NXProjectFileViewController(nibName: Constant.kProjecFilesNibName,bundle:nil)
        projectFileVC.view.frame  = self.fileListView.bounds
        projectFileVC.delegate = self
        projectFileVC.addObserver(self, forKeyPath: "displayData", context: nil)
        
        isProjectRootViewInit = true
        
        return projectFileVC
    }()
    lazy var projectTabViewController:NXProjectTabViewController = {
        let projectTabViewController = NXProjectTabViewController(nibName: Constant.kProjectTabViewNibName,bundle:nil)
        projectTabViewController.view.frame = self.fileListView.bounds
        projectTabViewController.addObserver(self, forKeyPath: "displayData", context: nil)
        
        isProjectViewInit = true
        
        return projectTabViewController
    }()
    lazy var projectNomarlFileVC: NXProjectNormalFileViewController = {
        let projectNomarlFileVC = NXProjectNormalFileViewController(nibName: Constant.kProjectNomalFileSNibName,bundle:nil)
        projectNomarlFileVC.view.frame = self.fileListView.bounds
        projectNomarlFileVC.delegate = self
        projectNomarlFileVC.addObserver(self, forKeyPath: "displayData", context: nil)
        
        isProjectFolderViewInit = true
        
        return projectNomarlFileVC
    }()
    
    lazy var workspace: NXBaseFileViewController = {
        let vc = NXWorkspaceViewController(nibName: Constant.kBaseFileViewController, bundle: nil)
        vc.delegate = self
        vc.view.frame = self.fileListView.bounds
        vc.addObserver(self, forKeyPath: "displayData", context: nil)
        
        isWorkspaceViewInit = true
        return vc
    }()
    
    // Fix bug 68040 - log out crash because of not remove observer.
    var isMyVaultViewInit = false
    var isShareWithMeViewInit = false
    var isOfflineViewInit = false
    var isProjectViewInit = false
    var isProjectRootViewInit = false
    var isProjectFolderViewInit = false
    var isWorkspaceViewInit = false
    
    
    var      manager: NetworkReachabilityManager?
    var projectModel: NXProjectModel?
    var     syncFile: NXSyncFile?
    
    /// Load status.
    var isLoading = false
    var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        initData()
    }
    
    func initData() {
        // Loading.
        self.view.addSubview(NXLoadingView.sharedInstance)
        isLoading = true
        NXMemoryDrive.sharedInstance.load { (error) in
            // Finish load.
            DispatchQueue.main.async {
                NXLoadingView.sharedInstance.removeFromSuperview()
            }
            self.isLoading = false
            self.loaded = true
            
            // TODO: Show alert
            if error != nil {
            }
            
            // Show UI.
            self.clickType = selectecType.outBox
            self.addViewControllers()
            self.addObserver()
        }
    }
    
    deinit {
        removeObserver()
    }
    
    func addObserver() {
        fileListViewController.addObserver(self, forKeyPath: "displayData", context: nil)
        NXClientUser.shared.addObserver(self, forKeyPath: "isOnline", options: .new, context: nil)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .startUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .stopUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploaded)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadFailed)
    }
    
    func removeObserver() {
        fileListViewController.removeObserver(self, forKeyPath: "displayData")
        NXClientUser.shared.removeObserver(self, forKeyPath: "isOnline")
        NotificationCenter.default.removeObserver(self)
        
        if isMyVaultViewInit { myVaultViewController.removeObserver(self, forKeyPath: "displayData") }
        if isOfflineViewInit { offlineViewController.removeObserver(self, forKeyPath: "displayData") }
        if isShareWithMeViewInit { sharedWithMeVC.removeObserver(self, forKeyPath: "displayData") }
        if isProjectRootViewInit { projectFileVC.removeObserver(self, forKeyPath: "displayData") }
        if isProjectViewInit { projectTabViewController.removeObserver(self, forKeyPath: "displayData") }
        if isProjectFolderViewInit { projectNomarlFileVC.removeObserver(self, forKeyPath: "displayData") }
        if isWorkspaceViewInit { workspace.removeObserver(self, forKeyPath: "displayData") }
        
    }
   
    override func viewWillAppear() {
        super.viewWillAppear()
        // Resize window
        if let window = view.window {
            if isFirstOpen == true{
                window.setContentSize(Constant.minWindowSize)
                isFirstOpen = false
            }
         
            self.view.window?.styleMask = NSWindow.StyleMask([.closable,.titled,.resizable,.miniaturizable])
            window.delegate = self
        }
    }
    
    func addViewControllers() {
         let viewController = NXLocalMainOperationViewController(nibName:  Constant.kOperationIdentifer, bundle: nil)
            viewController.view.frame = operationView.bounds
            viewController.delegate = self
            operationView.addSubview(viewController.view)
            operationViewController = viewController
    
        
         let viewController1 = NXLocalMainFileListViewController(nibName:  Constant.kFileListNibName, bundle: nil)
            viewController1.view.frame = fileListView.bounds
            fileListView.addSubview(viewController1.view)
            viewController1.delegate = self
            fileListViewController = viewController1
        
        
        let viewController2 = NXLocalMainFooterViewController(nibName:  Constant.kFooterIdentifer, bundle: nil)
            viewController2.view.frame = footerView.bounds
            viewController2.delegate = self
            footerView.addSubview(viewController2.view)
            footerViewController = viewController2
        
         let viewController3 = NXSiderBarViewController(nibName: Constant.kSiderBarNibName,bundle:nil)
            viewController3.view.frame = siderBarView.bounds
            viewController3.delegate = self
            siderBarView.addSubview(viewController3.view)
            siderBarViewController = viewController3
        
        preViewControllr = fileListViewController
    }
    fileprivate func showItem() {
        switch clickType {
        case .myVault?:
            footerViewController.displayItemCount(with: myVaultViewController.displayCount)
        case .sharedWithMe?:
            footerViewController.displayItemCount(with: sharedWithMeVC.displayCount)
        case .allOffline?:
            footerViewController.displayItemCount(with: offlineViewController.displayCount)
        case .outBox?:
            footerViewController.displayItemCount(with: fileListViewController.displayCount)
        case .none:
            footerViewController.displayItemCount(with: 0)
        case .project?:
            footerViewController.displayItemCount(with:projectTabViewController.displayCount)
        case .projectFolder?:
            footerViewController.displayItemCount(with: projectFileVC.displayCount)
        case .projectFile?:
            footerViewController.displayItemCount(with: projectNomarlFileVC.displayCount)
        case .workspace?:
            footerViewController.displayItemCount(with: workspace.displayCount)
        }
    }
    
    fileprivate func getCurrentDisplayCount() -> Int {
        var count = 0
        switch clickType {
        case .myVault?:
             count = myVaultViewController.getItemCount()
        case .sharedWithMe?:
            count = sharedWithMeVC.getItemCount()
        case .allOffline?:
            count = offlineViewController.getItemCount()
        case .outBox?:
            count = fileListViewController.getItemCount()
        case .project?:
            count = fileListViewController.getItemCount()
        case .projectFolder?:
            count = projectFileVC.getItemCount()
        case .none:
            count = 0
        case .projectFile?:
            break
        case .workspace?:
            break
        }
        return count
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "displayData" {
            DispatchQueue.main.async {
                self.showItem()
            }
            
        } else if keyPath == "isOnline" {
            operationViewController.updateNetworkStatus()
            footerViewController.updateNetworkStatus()
        }
    }
    
    @objc private func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .startUpload ||
        notification.nxNotification == .stopUpload ||
        notification.nxNotification == .uploadFailed {
            if clickType == .workspace {
                if let uploadFile = notification.object as? NXSyncFile {
                    for (i, file) in workspace.displayData.enumerated() {
                        if file.getNXLID() == uploadFile.file.getNXLID() {
                            file.status = uploadFile.syncStatus
                            DispatchQueue.main.async {
                                self.workspace.fileTableView.reloadData(forRowIndexes: [i], columnIndexes: [0])
                            }
                            
                            break
                        }
                    }
                }
            }
            
            
        } else if notification.nxNotification == .uploaded {
            if clickType == .workspace {
                if let uploadedFile = notification.object as? NXSyncFile,
                    uploadedFile.file.parent == workspace.folder {
                    
                    // Reload data.
                    if let folder = workspace.folder {
                        workspace.loadData(folder: folder, files: folder.children ?? [])
                    } else {
                        workspace.loadData(folder: nil, files: NXMemoryDrive.sharedInstance.getWorkspace())
                    }
                }
                
            }
        }
    }
}

// MARK: - Public methods.

extension NXLocalMainViewController {
    
    func getPermission(url: URL, completion: @escaping (Bool) -> ()) {
        
        if FileManager.default.contents(atPath: url.path) == nil {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = false
            openPanel.worksWhenModal = true
            openPanel.allowsMultipleSelection = false
            openPanel.message = "This application needs to access the directory to do the corresponding operation to protect the file, please directly click the allow button"   //本应用需要访问该目录，才能做保护文件的相应操作 请直接点击允许按钮
            openPanel.prompt = "Allow"
            openPanel.directoryURL = URL.init(string: NSHomeDirectory())
            openPanel.beginSheetModal(for: self.view.window!) { (result) in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                    YMLog(openPanel.urls)
                    completion(true)
                }else {
                    completion(false)
                }
            }
        }else {
            completion(true)
        }
        
    }
    
    func protectFile(urls: [URL]) {
        let vc          = NXHomeProtectVC()
        vc.delegate     = self
        vc.projectRoot  = self.siderBarViewController.projectList.last as? NXProjectRoot
        vc.projectModel = self.projectModel
        vc.syncFile     = self.syncFile
        
        let protectType: NXProtectType
        if self.clickType == .projectFolder || self.clickType == .projectFile {
            protectType = .project
        } else if self.clickType == .workspace {
            protectType = .workspace
        } else {
            protectType = .myVault
        }
        vc.protectType = protectType
        
        vc.selectedFile = urls.map() { .localFile(url: $0) }
        self.presentAsModalWindow(vc)
    }
    
    func shareFile(urls: [URL]) {
                let vc = NXHomeShareVC()
                vc.delegate = self
                vc.selectedFile = urls.map() { .localFile(url: $0) }
                self.presentAsModalWindow(vc)
        }
    

    
    func protectFile() {
        let action: ([URL]) -> Void = { urls in
            self.protectFile(urls: urls)
        }
        
        if let window = self.view.window {
            NXCommonUtils.openPanel(parentWindow: window, allowMultiSelect: true, completion: action)
        }
        
    }
    
    func shareFile() {
        let action: ([URL]) -> Void = { urls in
            let vc = NXHomeShareVC()
            vc.delegate = self
            vc.selectedFile = urls.map() { .localFile(url: $0) }
            self.presentAsModalWindow(vc)
        }
        
        if let window = self.view.window {
            NXCommonUtils.openPanel(parentWindow: window, allowMultiSelect: true, completion: action)
        }
    }
    func sortByFileName() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
            viewControllerA.sortTableviewOrderByName()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
            viewControllerB.sortTableviewOrderByName()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
            viewControllerC.sortTableviewOrderByName()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
            viewControllerD.sortTableviewOrderByName()
        } else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.sortTableviewOrderByName()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.sort(type: .name)
        }
    }
    
    func sortBySize() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
            viewControllerA.sortTableviewOrderBySize()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
            viewControllerB.sortTableviewOrderBySize()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
            viewControllerC.sortTableviewOrderBySize()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
            viewControllerD.sortTableviewOrderBySize()
        } else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.sortTableviewOrderBySize()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.sort(type: .size)
        }
    }
    func sortByLatsModifyTime() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
            viewControllerA.sortTableviewOrderByDateLastmodified()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
            viewControllerB.sortTableviewOrderByDateLastmodified()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
            viewControllerC.sortTableviewOrderByDateLastmodified()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
            viewControllerD.sortTableviewOrderByDateLastmodified()
        } else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.sortTableviewOrderByDateLastmodified()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.sort(type: .dateModified)
        }
    }
    
    func shareRecipients() {
        fileListViewController.shareSelectedFile()
    }
    
    func openFile() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
                viewControllerA.openSelectedFile()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
                viewControllerB.openSelectedFile()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
                viewControllerC.openSelectedFileOrOpenFolder()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
               viewControllerD.openSelectedFileOropenFolder()
        }else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.openSelectedFile()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.openSelectedFileOrOpenFolder()
        }
    }
    
    func removeFile() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
            viewControllerA.removeSelectedFile()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
            viewControllerB.removeSelectedFile()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
            viewControllerC.removeSelectedFile()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
            viewControllerD.removeSelectedFile()
        }else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.removeSelectedFile()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.removeSelectedFile()
        }

    }
    
    func viewFileInfo() {
        if let viewControllerA = preViewControllr as? NXMyVaultViewController {
            viewControllerA.viewSelectedFileInfo()
        } else if let viewControllerB = preViewControllr as? NXSharedWithMeVC {
            viewControllerB.viewSelectedFileInfo()
        } else if let viewControllerC = preViewControllr as? NXProjectFileViewController {
            viewControllerC.viewSelectedFileInfo()
        } else if let viewControllerD = preViewControllr as? NXProjectNormalFileViewController {
            viewControllerD.viewSelectedFileInfo()
        } else if let viewContrellerE = preViewControllr as? NXLocalMainFileListViewController {
            viewContrellerE.viewSelectedFileInfo()
        } else if let vc = preViewControllr as? NXBaseFileViewController {
            vc.viewSelectedFileInfo()
        }
    }
    
    func viewFileLog() {
        
    }
    
    func uploadAll() {
        fileListViewController.uploadAll()
    }
    
    func stopUploadAll() {
        fileListViewController.stopUploadAll()
    }
    
    func uploadFile() {
        self.uploadAll()
    }
    
    func stopUploadFile() {
        self.stopUploadAll()
    }
    
}

// MARK: Private methods.

extension NXLocalMainViewController {
    private func updateRefreshButton(type: selectecType) {
       operationViewController.updateRefreshButton(type: type)
    }
}

extension NXLocalMainViewController: NXLocalMainFooterViewControllerDelegate {
    func getItemCount() -> Int {
        return self.getCurrentDisplayCount()
    }
    
}

//MARK: - NXLocalMainOperationViewControllerDelegate
extension NXLocalMainViewController: NXLocalMainOperationViewControllerDelegate {
    func operationClicked(type: NXMainOperationBarOperationType, value: Any?) {
        switch type {
        case .search:
            if let searchString = value as? String {
                if preViewControllr == myVaultViewController {
                    myVaultViewController.filter(with: searchString)
                } else if preViewControllr == fileListViewController {
                    fileListViewController.filter(with: searchString)
                }else if preViewControllr == offlineViewController {
                    offlineViewController.filter(with: searchString)
                } else if preViewControllr == sharedWithMeVC {
                    sharedWithMeVC.filter(with: searchString)
                } else if preViewControllr == projectFileVC {
                    projectFileVC.filter(with: searchString)
                } else if preViewControllr == projectNomarlFileVC {
                    projectNomarlFileVC.filter(with: searchString)
                } else if preViewControllr == workspace {
                    workspace.search(include: searchString)
                }
                
            }
        case .protect:
            protectFile()
        case .share:
            shareFile()
        case .openNetwork:
            NXCommonUtils.openWebsite()
        case .startUploadAll:
            uploadAll()
            
        case .stopUploadAll:
            stopUploadAll()
            
        case .openPreference:
            let vc = NXPreferencesViewController()
            self.presentAsModalWindow(vc)
        case .refresh:
            refreshData()
        default:
            break
        }
    }
    
    fileprivate func refreshData() {
        
        siderBarViewController.refresh()
    }
}

extension NXLocalMainViewController: NSWindowDelegate {
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let minWidth = Constant.minWindowSize.width, minHeight = Constant.minWindowSize.height
        let width = (frameSize.width > minWidth) ? frameSize.width : minWidth
        let height = (frameSize.height > minHeight) ? frameSize.height : minHeight
        return NSSize(width: width, height: height)
    }
    
}

//MARK: - NXLocalMainFileListViewControllerDelegate
extension NXLocalMainViewController: NXLocalMainFileListViewControllerDelegate {
    func protect() {
        protectFile()
    }
    
    func share() {
        shareFile()
    }
}

//MARK: - NXHomeProtectVCDelegate
extension NXLocalMainViewController: NXHomeProtectVCDelegate {
    func protectFinish(files: [NXNXLFile]) {
        self.fileListViewController.refresh()
        
        if NXClientUser.shared.setting.getIsAutoUpload() {
            self.fileListViewController.uploadFile(files: files)
        }
    }
}

//MARK: - NXHomeShareVCDelegate
extension NXLocalMainViewController: NXHomeShareVCDelegate {
    func shareFinish(isNewCreated: Bool, files: [NXNXLFile]) {
        self.fileListViewController.refresh()
         self.myVaultViewController.refresh()
        
        if isNewCreated, NXClientUser.shared.setting.getIsAutoUpload() {
            self.fileListViewController.uploadFile(files: files)
        }
    }

}

//MARK: - NXSiderBarViewControllerDelegate
extension NXLocalMainViewController:NXSiderBarViewControllerDelegate {
    
    func operationClick(type: selectecType, value: Any?) {
        
        syncFile = nil
        switch type {
        case .myVault:
            preViewControllr = myVaultViewController
            operationViewController.searchField.isHidden = false
            // Reload data.
            myVaultViewController.initData(refresh: true)
        case .sharedWithMe:
            preViewControllr = sharedWithMeVC
            operationViewController.searchField.isHidden = false
            // Reload data.
            sharedWithMeVC.initData(refresh: true)
        case .allOffline:
            preViewControllr = offlineViewController
            operationViewController.searchField.isHidden = false
            // Reload data.
            offlineViewController.initData(refresh: true)
        case .outBox:
            preViewControllr = fileListViewController
            operationViewController.searchField.isHidden = false
            // Reload data.
            fileListViewController.initData()
        case .project:
            preViewControllr = projectTabViewController
            projectTabViewController.projectVC.delegate = self
            projectTabViewController.delegate = self
            operationViewController.searchField.isHidden = true
            projectTabViewController.data = value as! NXProjectRoot
        case .projectFolder:
            preViewControllr = projectFileVC
            nowSelected = siderBarViewController.projectOutlineView.selectedRow
            operationViewController.searchField.isHidden = false
            projectFileVC.delegate = self
            projectFileVC.data = value as? NXProjectModel ?? NXProjectModel()
            projectModel = value as? NXProjectModel
            syncFile = nil
        case .projectFile:
            preViewControllr = projectNomarlFileVC
            operationViewController.searchField.isHidden = false
            nowSelected = siderBarViewController.projectOutlineView.selectedRow
            if let newFile = value as? NXSyncFile {
                syncFile = newFile
                projectModel = nil
                if let useFile =  newFile.file as? NXProjectFileModel {
                    projectNomarlFileVC.data = useFile
                }
            }
        case .workspace:
            preViewControllr = workspace
            if let file = value as? NXFileBase {
                let syncFile = NXSyncFile(file: file)
                syncFile.syncStatus = file.status
                self.syncFile = syncFile
                workspace.loadData(folder: file, files: file.children ?? [])
            } else {
                workspace.loadData(folder: nil, files: NXMemoryDrive.sharedInstance.getWorkspace())
            }
            
            operationViewController.searchField.isHidden = false
        }
        if !operationViewController.searchField.stringValue.isEmpty {
            restoreData()
        }
        clickType = type
        let subviews = fileListView.subviews
        for i in subviews {
            i.removeFromSuperview()
        }
        showItem()
        updateRefreshButton(type: type)
        operationViewController.searchField.stringValue = ""
        preViewControllr.view.frame = fileListView.bounds
        fileListView.addSubview(preViewControllr.view)
        operationViewController.fromType = (clickType == .project || clickType == .projectFolder || clickType == .projectFile || clickType == .workspace) ? .project : .myVault
        
        
    }
    
    fileprivate func restoreData() {
        switch clickType {
        case .myVault?:
            myVaultViewController.filterCompletioned()
        case .sharedWithMe?:
            sharedWithMeVC.filterCompletioned()
        case .allOffline?:
            offlineViewController.filterCompletioned()
        case .outBox?:
            fileListViewController.filterCompletioned()
        case .project?:
            projectTabViewController.projectVC.filterCompletioned()
        case .none:
            return
        case .projectFolder?:
            projectFileVC.filterCompletioned()
        case .projectFile?:
            projectNomarlFileVC.filterCompletioned()
        case .workspace?:
            break
        }
    }
}

//MARK: - add file to project
extension NXLocalMainViewController {
    func addFileToProject(file: NXProjectFileModel) {
        let addFileVC = NXAddFiletoProjectVC()
        addFileVC.delegate = self
        addFileVC.preFileModel = file
        addFileVC.rootModel = self.siderBarViewController.projectList.last as? NXProjectRoot
        self.presentAsModalWindow(addFileVC)
    }
    
    func addFileToProjectWith(path: String, tags: [String: [String]]) {
        if (self.siderBarViewController.projectList.last as? NXProjectRoot) != nil {
                    let addFileVC = NXAddFiletoProjectVC()
                    addFileVC.delegate  = self
                    addFileVC.filePath  = path
                    addFileVC.tags      = tags // Not use
                    addFileVC.rootModel = self.siderBarViewController.projectList.last as? NXProjectRoot
            DispatchQueue.main.async {
                  self.presentAsModalWindow(addFileVC)
            }
                }
            
        }
    }



extension NXLocalMainViewController: NXAddFiletoProjectVCDelegate {
    func addFileToProjectActionFinished(files: [NXNXLFile]) {
        self.fileListViewController.refresh()
        if NXClientUser.shared.setting.getIsAutoUpload() {
            self.fileListViewController.uploadFile(files: files)
        }
    }
}

extension NXLocalMainViewController:NXProjectFileViewControllerDelegate {
    func addFileToProject(nxlFile: NXProjectFileModel) {
        addFileToProject(file: nxlFile)
    }
    
    func openFolder(item: Any) {
        siderBarViewController.select(item: item)
    }
}
extension NXLocalMainViewController:NXProjectNormalFileViewControllerDelegate {
    func addFileToProjectOfNormal(nxlFile: NXProjectFileModel) {
        addFileToProject(file: nxlFile)
    }
      
    func openNewFolder(item: Any) {
        siderBarViewController.select(item: item)
    }
}
extension NXLocalMainViewController:NXProjectViewControllerDelegate {
    func openProject(item:Any) {
        nowSelected  =   siderBarViewController.projectOutlineView.row(forItem: item)
        let indexSet = IndexSet([nowSelected])
        siderBarViewController.projectOutlineView.deselectRow(siderBarViewController.projectOutlineView.selectedRow)
        siderBarViewController.projectOutlineView.centreRow(row: nowSelected, animated: true)
        siderBarViewController.projectOutlineView.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
}
extension NXLocalMainViewController:NXProjectTabViewControllerDelegate {
    func getDisplayCount(_ displayCount: Int) {
        footerViewController.displayItemCount(with: displayCount)
    }
}

extension NXLocalMainViewController: NXMyVaultViewControllerDelegate {
}

extension NXLocalMainViewController: NXBaseFileViewControllerDelegate {
    func openFolder(file: NXFileBase) {
        siderBarViewController.select(item: file)
    }
}
