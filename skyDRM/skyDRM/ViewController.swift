//
//  ViewController.swift
//  skyDRM
//
//  Created by eric on 2016/12/29.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

import Cocoa

//import RepositoryView

class ViewController: NSViewController, NSWindowDelegate {
    
    fileprivate struct Constant {
        // Display message
        static let shareFolderWarningMessage = NSLocalizedString("VIEW_CONTROLLER_INVALID_OPERATION", comment: "")
    }
    
    @IBOutlet weak var topBarView: NSView!
    @IBOutlet weak var leftBarView: NSView!
    @IBOutlet weak var contentView: NSView!
    
    fileprivate let accountViewController = NXAccountViewController()
    fileprivate let repositoryVC = NXRepositoryViewController()
    fileprivate let backgroundView = NSView()
    var navView: NXMainNavigationView!
    
    var homeView: NXHomeView?
    var fileListView: NXFileListView?
    var mainProjectView: NXMainProjectView?
    
    fileprivate var heartbeatService:NXHeartbeatService?
    
    var currentSubViewInContent: NSView? = nil
    private var tokenExpiredFlag:Bool = false
    var shouldGetWaterMarkConfig:Bool = false
    
    fileprivate var dropDownListViewController: NXSpecificProjectTitlePopupViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hostURLString = NXCommonUtils.getCurrentRMSAddress()
        
        // Do any additional setup after loading the view.
        navView = NXCommonUtils.createViewFromXib(xibName: "NXMainNavigationView", identifier: "MainNavigationView", frame: nil, superView: leftBarView) as? NXMainNavigationView
        
        navView?.doWork()
        navView?.mainNavigationDelegate = self
        navView?.navTableView.selectRowIndexes([0], byExtendingSelection: false)
        leftBarView.frame.size = NSZeroSize
        contentView?.frame = self.view.bounds
        NXCommonUtils.setLoginFinishTicketCount()
        heartbeatService = NXHeartbeatService(userID: (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!, ticket: (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!)
        heartbeatService?.delegate = self;
        
        heartbeatService?.getWaterMarkConfigInfoWith(platformId: NXCommonUtils.getPlatformId())
        
        NotificationCenter.default.addObserver(self, selector:#selector(didRecvTokenExpiredMsg(notification:)),
                                               name: NSNotification.Name(rawValue: SKYDRM_TOKEN_EXPIRED), object: nil)
        NXMainMenuHelper.shared.onMainViewController()
    }

    func didRecvLogOutMsg(notification:NSNotification){
        Swift.print("didMsgRecv: \(String(describing: notification.userInfo))")
        
        self.onAccountLogout()
    }
    
    @objc func didRecvTokenExpiredMsg(notification:NSNotification){
        weak var weakSelf = self
        if tokenExpiredFlag == false {
            synchronized(lock: self) {
                weakSelf?.tokenExpiredFlag = true
                NSAlert.showAlert(withMessage: NSLocalizedString("SKYDRM_Token_Expired_Tips", comment: ""), informativeText: "", dismissClosure: { (type) in
                    if type == .sure {
                        weakSelf?.onAccountLogout()
                    }
                })
            }
        }
    }
    
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    override func viewWillAppear() {
        
        topBarView.layer?.backgroundColor = GREEN_COLOR.cgColor
        //    leftBarView.layer?.backgroundColor = CGColor(red: 57.0 / 255, green: 150.0 / 255, blue: 73.0 / 255, alpha: 1)
        leftBarView.layer?.backgroundColor = NSColor.gray.cgColor
        contentView.layer?.backgroundColor = BK_COLOR.cgColor
        //    self.view.window?.delegate = self
        NSApplication.shared.windows.first?.delegate = self
        self.backgroundView.wantsLayer = true
        self.backgroundView.frame = self.view.frame
        self.backgroundView.layer?.backgroundColor = NSColor.gray.cgColor
        self.backgroundView.alphaValue = 0.5
        self.view.addSubview(backgroundView)
        backgroundView.isHidden = true
        accountViewController.delegate = self
        repositoryVC.delegate = self
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        _ = self.view.window?.styleMask.insert(NSWindow.StyleMask.resizable)
        
        startPendingTask()
    }
    
    func startPendingTask() {
        let isFolderPath: (String) -> Bool = {
            path in
            let attr = try? FileManager.default.attributesOfItem(atPath: path)
            if let type = attr?[FileAttributeKey.type] as? FileAttributeType,
                type == .typeDirectory {
                return true
            }
            
            return false
        }
        
        // open file
        let openFilePaths = PendingTask.sharedInstance.getFilePaths(with: .openFile)
        let filePaths = openFilePaths.flatMap() { $0 }
        for filePath in filePaths {
            if NXFileRenderSupportUtil.renderFileType(fileName: filePath) == NXFileContentType.NOT_SUPPORT {
                NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_NOT_SUPPORT_TYPE_RENDER", comment: ""))
            } else {
            }
            
        }
        
        // Check encrypt and decrypt
        let en_DecryptFilePaths = PendingTask.sharedInstance.getFilePaths(with: .encryptAndDecrypt)
        if !en_DecryptFilePaths.isEmpty {
            let client = NXLoginUser.sharedInstance.nxlClient
            
            var filterFilePaths = [[String]]()
            for paths in en_DecryptFilePaths {
                var fileterFilePath = [String]()
                for item in paths {
                    if client?.isNXLFile(URL(fileURLWithPath: item)) == false {
                        fileterFilePath.append(item)
                    }
                }
                
                if fileterFilePath.count != 0 {
                    filterFilePaths.append(fileterFilePath)
                }
            }
            
            if filterFilePaths.count != 0 {
                NXEncryptDecryptWindowController.sharedInstance.showWindow(nil)
                guard let viewController = NXEncryptDecryptWindowController.sharedInstance.contentViewController as? NXEncryptDecryptViewController else {
                    return
                }
                viewController.addPendingTasks(en_DecryptFilePaths: filterFilePaths)
            }
        }
        
        // Share file
        let shareFilePaths = PendingTask.sharedInstance.getFilePaths(with: .shareFile)
        if !shareFilePaths.isEmpty {
            let paths = shareFilePaths.flatMap() { $0 }
            
            /// FIXME: the display of UI is not good
            for path in paths {
                if isFolderPath(path) {
                    NSAlert.showAlert(withMessage: Constant.shareFolderWarningMessage)
                } else {
                    NXShareFromContextMenuWindowController.sharedInstance.showWindow(nil)
                    guard let viewController = NXShareFromContextMenuWindowController.sharedInstance.contentViewController as? NXShareFromContextMenuViewController else {
                        return
                    }
                    viewController.addTask(with: [(true, path)])
                }
                
            }
            
        }
        
        // Protect file
        let protectFilePaths = PendingTask.sharedInstance.getFilePaths(with: .protectFile)
        if !protectFilePaths.isEmpty {
            let paths = protectFilePaths.flatMap() { $0 }
            debugPrint("jinle")
            /// FIXME: the display of UI is not good
            for path in paths {
                if isFolderPath(path) {
                    NSAlert.showAlert(withMessage: Constant.shareFolderWarningMessage)
                } else {
                    NXShareFromContextMenuWindowController.sharedInstance.showWindow(nil)
                    guard let viewController = NXShareFromContextMenuWindowController.sharedInstance.contentViewController as? NXShareFromContextMenuViewController else {
                        return
                    }
                    viewController.addTask(with: [(false, path)])
                }
                
            }
            
        }
        
        /// check permission
        let checkPermissions = PendingTask.sharedInstance.getFilePaths(with: .checkPermission)
        let checkPermissionPaths = checkPermissions.flatMap() { $0 }
        /// FIXME: the display of UI is not good
        for path in checkPermissionPaths {
            if isFolderPath(path) {
                NSAlert.showAlert(withMessage: Constant.shareFolderWarningMessage)
            } else {
                NXCheckPermissionCenter.sharedInstance.checkPermission(from: path)
            }
            
        }
        
        /// remove all pending task
        _ = PendingTask.sharedInstance.removeAll()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: SKYDRM_TOKEN_EXPIRED), object: nil)
    }
    
    func dialogServerDisconnected(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = .informational
        myPopup.addButton(withTitle: "Retry")
        myPopup.addButton(withTitle: "Log Out")
        let res = myPopup.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            
            // should try connect server to check token again
            return true
        }
        
        if res == NSApplication.ModalResponse.alertSecondButtonReturn {
            
            // should log out
            return true
        }
       
        return false
    }
    
    func dialogTokenInvalid(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = .warning
        myPopup.addButton(withTitle: "OK")
        let res = myPopup.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            // should log out
           // self.accountLogout
            return true
        }
        return false
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    

    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize{
        var newFrameSize = frameSize
        
        if newFrameSize.width < 1160{
            newFrameSize.width = 1160
        }
        
        if newFrameSize.height < 640{
            newFrameSize.height = 640
        }
        
        
        return newFrameSize
    }
    func windowWillClose(_ notification: Notification) {
        NSRunningApplication.current.terminate()
    }
    func windowDidResignMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidResignKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidBecomeKey(_ notification: Notification) {
        updateMainMenu()
    }
    func windowDidBecomeMain(_ notification: Notification) {
        updateMainMenu()
    }
    fileprivate func updateMainMenu() {
        if let _ = self.view.window?.attachedSheet {
            NXMainMenuHelper.shared.onModalSheetWindow()
        }
        else {
            NXMainMenuHelper.shared.onMainViewController()
            if currentSubViewInContent is NXHomeView {
                NXMainMenuHelper.shared.onHomeView()
            }
            else if currentSubViewInContent is NXFileListView {
                NXMainMenuHelper.shared.onFileListView()
                let view = currentSubViewInContent as! NXFileListView
                if let bar = view.fileOperationBar {
                    NXMainMenuHelper.shared.enablePrevious(enable: bar.backBtn.isEnabled)
                    NXMainMenuHelper.shared.enableNext(enable: bar.forwardBtn.isEnabled)
                    if let files = fileListView?.selectedFiles,
                        files.count > 0 {
                        
                        if let files = files as? [NXSharedWithMeFile] {
                            if files.count > 1 {
                                NXMainMenuHelper.shared.settingShareWithMeMenu(with: nil)
                            } else {
                                if files.first?.getIsOwner() == true {
                                   NXMainMenuHelper.shared.settingShareWithMeMenu(with: [.view, .edit, .print, .share, .saveAs, .watermark])
                                } else {
                                    NXMainMenuHelper.shared.settingShareWithMeMenu(with: files.first?.rights)
                                }
                            }
                        } else {
                            let is3rdRepo = NXCommonUtils.is3rdRepo(node: files[0])
                            NXMainMenuHelper.shared.onSelectFileEx(file: files[0], is3rdRepo: is3rdRepo)
                        }
                        
                    }
                    
                    if bar.uploadFileButton.isEnabled == true {
                        NXMainMenuHelper.shared.enableUpload(enable: !bar.uploadFileButton.isHidden)
                    }
                    else {
                        NXMainMenuHelper.shared.enableUpload(enable: false)
                    }
                }
            }
            else {
                NXMainMenuHelper.shared.onProjectHomeView()
            }
        }
        updateProjectMenu()
    }
    fileprivate func updateProjectMenu() {
        if let homeview = currentSubViewInContent as? NXHomeView {
            homeview.homeBottomView?.updateProjectMenu()
        }
        else if let listView = currentSubViewInContent as? NXFileListView {
            if let popupProjectVC = listView.window?.attachedSheet?.contentViewController as? NXSpecificProjectTitlePopupViewController {
                popupProjectVC.updateProjectMenu()
            }
        }
        else if let projectView = currentSubViewInContent as? NXMainProjectView {
            projectView.updateProjectMenu()
        }

    }
}

extension ViewController: NXMainNavigationDelegate {
    func navButtonClicked(index: Int) {
        if index == 1000{
            accountViewController.mainView = .logout
            backgroundView.frame = self.view.frame
            backgroundView.isHidden = false
            self.presentAsModalWindow(accountViewController)
            return
        }
        else if index == 1001 {
            accountViewController.mainView = .manageProfile
            backgroundView.frame = self.view.frame
            backgroundView.isHidden = false
            self.presentAsModalWindow(accountViewController)
            return
        }
        
        switch index {
        case 0:
            if homeView == nil {
                homeView = NXCommonUtils.createViewFromXib(xibName: "NXHomeView", identifier: "homeView", frame: nil, superView: self.contentView) as? NXHomeView
            }
            homeView?.updateUIFromNetwork()
            homeView?.delegate = self
            currentSubViewInContent = homeView
            homeView?.isHidden = false
            
            fileListView?.isHidden = true
            mainProjectView?.isHidden = true
        case 1:
            if fileListView == nil {
                fileListView = NXCommonUtils.createViewFromXib(xibName: "NXFileListView", identifier: "filesView", frame: nil, superView: self.contentView) as? NXFileListView
            }
            fileListView?.viewController = self
            fileListView?.isHidden = false
            fileListView?.delegate = self
            currentSubViewInContent = fileListView
            fileListView?.doWork()
            fileListView?.updateUI()
            
            homeView?.isHidden = true
            mainProjectView?.isHidden = true
        case 2:
            if mainProjectView == nil {
                mainProjectView = NXCommonUtils.createViewFromXib(xibName: "NXMainProjectView", identifier: "mainProject", frame: nil, superView: self.contentView) as? NXMainProjectView
            }
            mainProjectView?.isHidden = false
            mainProjectView?.delegate = self
            mainProjectView?.doWork()
            currentSubViewInContent = mainProjectView
            
            homeView?.isHidden = true
            fileListView?.isHidden = true
        default:
            break
        }
        updateMainMenu()
    }
}

extension ViewController: NXAccountVCDelegate {
    func onAccountVCClose() {
        backgroundView.isHidden = true
    }
    func onAccountLogout() {
        //clear WKWebView of NXLMacLoginVC
        let cookiesStorage = HTTPCookieStorage.shared
        if let cookies = cookiesStorage.cookies {
            for cookie in cookies {
                cookiesStorage.deleteCookie(cookie)
            }
        }
        if let currentClient = NXLoginUser.sharedInstance.nxlClient {
            // TODO: error handle
            try? currentClient.signOut()
            NXLoginUser.sharedInstance.clear()
        }
        
        NXSpecificProjectWindow.sharedInstance.closeCurrentWindow()
        NXFileRenderManager.shared.closeAllFile()
        
        accountViewController.presentingViewController?.dismiss(accountViewController)
        // Fix bug: close or exit crash
        NSApplication.shared.windows.first?.delegate = nil
        
        if let controller =  self.storyboard?.instantiateController(withIdentifier:  "WelcomeViewController"), let welcome = controller as? WelcomeViewController {
            self.view.window?.contentViewController = welcome
        }
        
        
    }
    
    func onAccountAvatar() {
        navView.refreshAvatar()
        if currentSubViewInContent is NXHomeView {
            (currentSubViewInContent as! NXHomeView).refreshUI()
        }
    }
    func onAccountName() {
        if let view = currentSubViewInContent as? NXHomeView {
            view.refreshAccountName()
        }
        else if let view = currentSubViewInContent as? NXMainProjectView {
            view.updateAccountName()
        }
    }
}
extension ViewController: NXFileListViewDelegate {
    func shouldGoToHomePage() {
        let homeId: Int = 0
        navView?.navTableView.selectRowIndexes([homeId], byExtendingSelection: false)
        navButtonClicked(index: homeId)
    }
    
    func showDropDownList() {
        let viewController = NXSpecificProjectTitlePopupViewController()
        self.presentAsSheet(viewController)
        
        self.dropDownListViewController = viewController
    }
    
}
extension ViewController: NXMainProjectViewDelegate {
    func gobackHome() {
        let homeId: Int = 0
        navView?.navTableView.selectRowIndexes([homeId], byExtendingSelection: false)
        navButtonClicked(index: homeId)
    }
    func activateProject() {
        homeOpenProjectActivate()
    }
}
extension ViewController: NXHomeViewDelegate {
    func homeOpenRepositoryVC() {
        backgroundView.frame = self.view.frame
        backgroundView.isHidden = false
        self.presentAsModalWindow(repositoryVC)
    }
    
    func homeGotoMySpace(type: RepoNavItem, alias: String) {
        let myspaceId:Int = 1
        navView?.navTableView.selectRowIndexes([myspaceId], byExtendingSelection: true)
        navButtonClicked(index: myspaceId)
        fileListView?.navView.selectItem(type: type, alias: alias)
    }
    func homeRefreshAvatar() {
        navView.refreshAvatar()
    }
    func homeOpenProject() {
        if let _ = self.view.window?.attachedSheet {
            return
        }
        self.view.window?.makeKeyAndOrderFront(nil)
        let projectId:Int = 2
        navView?.navTableView.selectRowIndexes([projectId], byExtendingSelection: false)
        navButtonClicked(index: projectId)
    }
    func homeOpenAccountVC() {
        navButtonClicked(index: 1000)
    }
    func homeOpenProjectActivate() {
        self.view.window?.delegate = nil
        if let controller =  self.storyboard?.instantiateController(withIdentifier:  "NXProjectActivateViewController") as? NXProjectActivateViewController {
            self.view.window?.contentViewController = controller
        }
    }
}
extension ViewController: NXRepositoryVCDelegate {
    func onRepositoryVCClose() {
        backgroundView.isHidden = true
        if currentSubViewInContent is NXHomeView {
            (currentSubViewInContent as! NXHomeView).refreshUI()
        }
        
    }
}

extension NSTextField {
    private var commandKey: UInt {
        get {
            return NSEvent.ModifierFlags.command.rawValue
        }
    }
    
    private var commandShiftKey: UInt {
        get {
            return NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        }
    }
    
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

extension ViewController:NXHeartbeatServiceDelegate{
    
    func getWaterMarkConfigFinished(waterMarkConfigModel:NXWaterMarkContentModel?,error: Error?)
    {
        if error == nil {
            shouldGetWaterMarkConfig = false
            NXCommonUtils.waterMarkConfig = waterMarkConfigModel
        }
        else
        {
            if shouldGetWaterMarkConfig == false {
                heartbeatService?.getWaterMarkConfigInfoWith(platformId: NXCommonUtils.getPlatformId())
                shouldGetWaterMarkConfig = true
            }
            else
            {
                weak var weakself = self
                let concurrentQueue = DispatchQueue(label: "skyDRM_getWaterMarkConfig_Queue", attributes: .concurrent)
                let deadlineTime = DispatchTime.now() + .seconds(120)
                concurrentQueue.asyncAfter(deadline: deadlineTime) {
                      weakself?.heartbeatService?.getWaterMarkConfigInfoWith(platformId: NXCommonUtils.getPlatformId())
                }
            }
        }
    }
}
