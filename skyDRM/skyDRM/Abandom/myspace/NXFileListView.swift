//
//  NXFileListView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/12.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

enum FileListType:Int {
    case kTypeNormal
    case kTypeFavorite
    case kTypeOffline
    case kTypeMyVault
}

class NXFileListView: NXProgressIndicatorView, NXServiceOperationDelegate, NXDataViewDelegate{

    weak var viewController: NSViewController? = nil
    
    var serviceType = ServiceType.kServiceOneDrive
    
    var showType = FileListType.kTypeNormal
    
    var currentSelectedItem:RepoNavItem?
    var currentSelectedCloudDriveBoundService:NXBoundService?=nil
    var currentSelectedCloudDriveFolder:NXFileBase?=nil
    
    var waitView:NXWaitingView!
    var fileTableWaitView:NXWaitingView!

    var navView: NXRepoNavView!
    
    weak var delegate: NXFileListViewDelegate?

    @IBOutlet weak var repoNavView: NSView!
    
    @IBOutlet weak var leftPanelView: NSView!
    
    @IBOutlet weak var titleView: NSView!
    @IBOutlet weak var homeBtn: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    
    // store current node
    fileprivate var curNode: NXFileBase? = nil
    private var curBoundService: NXBoundService? = nil
    fileprivate var curShownFiles = NSMutableArray() {
        willSet {
            self.switchFileList()
        }
    }
    
    // store all bound services, like dropbox, googledrive...
    var allBoundServices:[(boundService:NXBoundService, root: NXFileBase)] = []
    
    // store all shown service
    var allShownServices:[(boundService:NXBoundService, root: NXFileBase)] = []
    
    private var viewTitleBar: NSView? = nil
    
    // 2 file show type view
    fileprivate var dataTableView: NXFileTableView? = nil
    fileprivate var dataMyVaultTableView: NXMyVaultFileTableView? = nil
    fileprivate var dataGridView: NXFileGridView? = nil
    
    var fileOperationBar: NXFileOperationBar? = nil
    // selected files/folders
    var selectedFiles:[NXFileBase] = []
    
    fileprivate let navViewWidth: CGFloat = 200
    private let fileOperationBarHeight: CGFloat = 80
    
    private var inited = false
        
    fileprivate var logService:NXLogService?
    fileprivate var currentSeletedMyVaultFileForDelete:NXNXLFile?
    
    
    var shareBtnLock = false
    
    fileprivate var viewedHistory: PreviousViewed? {
        return fileOperationBar?.viewedHistory
    }
    
    /// As myvault is the first one of navView, so first time no need to refresh
    fileprivate var shouldMyVaultRefresh: Bool = true
    
    //MARK: put into progress tree after check download rights
    fileprivate var downloadFiles = [NXFileBase]()
    fileprivate var checkedDownloadFiles = [NXFileBase]()
    fileprivate var downloadURL = URL(fileURLWithPath: "")
    
    fileprivate var firstTimeRefresh: Bool = true
    
    fileprivate var isSharedWithMe: Bool {
        get {
            return dataMyVaultTableView?.isSharedWithMe ?? false
        }
    }
    
    var serviceManger = NXRestOperationManager<NXBaseOperationItem>()
    
    override func onCancelAnimation(_ sender: Any) {
        NXAuthMgr.shared.cancel()
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        createFileView()
        createFileOperationBar()
        
        initTitleView()
        
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!
        logService = NXLogService(userID: userId, ticket: ticket)
    }
    
    func focusSearchField() {
        guard let fileOperationBar = fileOperationBar else {
            return
        }
        fileOperationBar.focusSearchField()
    }
    func sortbyFilename(){
        if currentSelectedItem == .myVault ||
            currentSelectedItem == .deleted ||
            currentSelectedItem == .shared ||
            currentSelectedItem == .favoriteFiles {
            dataMyVaultTableView?.sortbyFileName()
        }
        else {
            dataTableView?.sortbyFileName()
        }
    }
    
    func sortbyLastmodified() {
        if currentSelectedItem == .myVault ||
            currentSelectedItem == .deleted ||
            currentSelectedItem == .shared ||
            currentSelectedItem == .favoriteFiles {
            dataMyVaultTableView?.sortbyLastModified()
        }
        else {
            dataTableView?.sortbyLastModified()
        }
    }
    
    func sortbyFilesize() {
        if currentSelectedItem == .myVault ||
            currentSelectedItem == .deleted ||
            currentSelectedItem == .shared ||
            currentSelectedItem == .favoriteFiles {
            dataMyVaultTableView?.sortbyFileSize()
        }
        else {
            dataTableView?.sortbyFileSize()
        }
    }
    
    func doWork()  // should be invoked by caller
    {
        if inited {
            return
        }

        // get bound service from core data
        allBoundServices = CacheMgr.shared.getAllBoundService(userId: (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!)

        // show repo navigation view
        navView = NXCommonUtils.createViewFromXib(xibName: "NXRepoNavView", identifier: "repoNavView", frame: nil, superView: repoNavView) as? NXRepoNavView
        
        if navView == nil{
            Swift.print("failed to create repo nav view")
        }else{
            navView?.repoNavDelegate = self
            // NXRepoNavView will select "all files" by default. data will be refeshed in extension NXFileListView: NXRepoNavDelegate
            var reposUnderAllFiles:[(boundService:NXBoundService, root: NXFileBase)] = []
            for repo in allBoundServices{
                if repo.boundService.serviceType == ServiceType.kServiceMyVault.rawValue{
                    continue
                }
                reposUnderAllFiles.append(repo)
            }
            navView?.doWork(allBoundServices: reposUnderAllFiles)
        }
        
        // add notification
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(myVaultDidChanged(notification:)),
                                               name: NSNotification.Name("myVaultDidChanged"),
                                               object: nil)
        
        inited = true
    }
    
    @objc func myVaultDidChanged(notification: NSNotification) {
        
        if self.isHidden == false,
            allShownServices.count == 1,
            let bs = allShownServices.first,
            bs.boundService.serviceType == ServiceType.kServiceMyVault.rawValue {
            // refresh myvault
            DispatchQueue.main.async {
                self.waitView.isHidden = false
                self.fileTableWaitView.isHidden = false
                self.retrieveFilesFromNetwork(bs: bs.boundService, root: bs.root)
            }
            
        } else {
            shouldMyVaultRefresh = true
        }
        
    }
    
    func updateUI() {
        let items = NXLoginUser.sharedInstance.repository()
        var bs = items.map() { $0.correspondNXBoundService() }
        
        let myDrives = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceSkyDrmBox)
        if myDrives.count == 1, let myDrive = myDrives.first {
            bs.insert(myDrive, at: 0)
        }
        
        allBoundServices = bs.map() {
            bs -> (NXBoundService, NXFileBase) in
            let root = NXFolder()
            root.isRoot = true
            root.boundService = bs
            root.fullPath = "/"
            root.fullServicePath = "/"
            return (bs, root)
        }

        if navView != nil {
            navView.updateUI(allBoundServices: allBoundServices)
        }
        
    }
    func updateMySpaceStorageUI() {
        NXLoginUser.sharedInstance.updateMySpaceStorage()
    }
    
    func DeleteFileItemTips(fileBase:NXFileBase){
        let question:String
        let title:String
        
        if ((fileBase as? NXFolder) != nil) {
            question = NSLocalizedString("DELETE_FOLDER_TIPS", comment: "")
            title = NSLocalizedString("TITLE_DELETE_FOLDER", comment: "")
        } else {
            question = NSLocalizedString("DELETE_FILE_TIPS", comment: "")
            currentSeletedMyVaultFileForDelete = nil
            title = NSLocalizedString("TITLE_DELETE_FILE", comment: "")
        }
    
        NSAlert.showAlert(withMessage: question, confirmButtonTitle: NSLocalizedString("Confirm", comment: ""), cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), defaultCancelButton: true, titleName: title) { (type) in
            if .sure == type {
                guard self.deleteFileItemWith(boundService: (fileBase.boundService)!, fileItem: fileBase) else {
                    NXToastWindow.sharedInstance?.toast(String(format: NSLocalizedString("MY_SPACE_DELETE_FAILED", comment: ""), fileBase.name))
                    return
                }
                
                self.unmarkAllFlag(file: fileBase)
            }
        }
    }
    
    func unmarkAllFlag(file: NXFileBase) {
        if file.isFavorite {
            if file.repoId == "" {
                file.repoId = file.boundService?.repoId ?? ""
            }
            
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            let service = NXRepositoryFileService(withUserID: userId!, ticket: ticket!)
            service.delegate = self
            service.unmarkFavFile(files: [file])
        }
    }
    
    fileprivate func clearFileList() {
        switchDataView()
        fileOperationBar?.showNode(node: nil)
        
        // clean data view first
        curShownFiles.removeAllObjects()
        selectedFiles.removeAll()
        refreshDataView(showEmptyImage: false)
        
        fileOperationBar?.enableUploadButton(enable: false)
        NXMainMenuHelper.shared.enableUpload(enable: false)
        curBoundService = nil
        curNode = nil
    }
    
    fileprivate func showFileList() {
        clearFileList()
        
        guard let current = currentSelectedItem else {
            return
        }
        switch current {
        case .favoriteFiles:
            reloadFileList()
            if firstTimeRefresh {
                firstTimeRefresh = false
                
                fileTableWaitView.isHidden = false
                waitView.isHidden = false
                syncFavFromNetwork()
            }
            
        case .offlineFiles:
            reloadFileList()
            
        case .deleted:
            
            dataMyVaultTableView?.currentType = .deleted
            reloadFileList()
            
        case .shared:
            
            dataMyVaultTableView?.currentType = .allShare
            reloadFileList()
            
        default:
            break
        }
        
    }
    
    fileprivate func showFileListUnderRoot()  // root is very special since it can have multiple cloud drives
    {
        if currentSelectedItem == .allFiles{
            fileOperationBar?.hiddenCreateFolderButton(isHidden: true)
            fileOperationBar?.hiddenUploadButton(isHidden: true)
            fileOperationBar?.enableDownloadButton(enable: false)
            
            NXMainMenuHelper.shared.enableUpload(enable: false)
        }
        
        switchDataView()
        
        fileOperationBar?.showNode(node: nil)
        
        // clean data view first
        curShownFiles.removeAllObjects()
        selectedFiles.removeAll()
        refreshDataView(showEmptyImage: false)
        
        curBoundService = nil
        curNode = nil
        
        for tmp in allShownServices
        {
            
            let bs = tmp.boundService
            let root = tmp.root
            
            
            // try to recover data from core data
            CacheMgr.shared.getFilesUnderRoot(bs: bs, root: root)
            
            
            /// myvault
            // 1. get data from core data and display
            // 2. if need refresh, send request
            if bs.serviceType == ServiceType.kServiceMyVault.rawValue {
                if isSharedWithMe == true {
                    if DBSharedWithMeFileHandler.shared.getAll().count != 0 {
                        refreshData()
                    }
                    
                    waitView.isHidden = false
                    fileTableWaitView.isHidden = false
                    self.retrieveFilesFromNetwork(bs: bs, root: root)
                } else {
                    if root.getChildren()?.count != 0 {
                        refreshData()
                    }
                    waitView.isHidden = true
                    fileTableWaitView.isHidden = true
                    
                    if shouldMyVaultRefresh {
                        shouldMyVaultRefresh = false
                        
                        waitView.isHidden = false
                        fileTableWaitView.isHidden = false
                        self.retrieveFilesFromNetwork(bs: bs, root: root)
                    }
                }

                return
            }
            
            if root.getChildren()?.count == 0{  // no data in core data, try to get from network
                waitView.isHidden = false
                fileTableWaitView.isHidden = false
                self.retrieveFilesFromNetwork(bs: bs, root: root)
            }else{  // has local data, show directly
                refreshData()
                waitView.isHidden = true
                fileTableWaitView.isHidden = true

            }
            
        }
        
    }
    
    fileprivate func showFilesUnderFolder(folder: NXFileBase)
    {
        if currentSelectedItem == .allFiles,
            folder.boundService?.serviceType == ServiceType.kServiceSkyDrmBox.rawValue{
            fileOperationBar?.hiddenCreateFolderButton(isHidden: false)
            fileOperationBar?.hiddenUploadButton(isHidden: false)
            fileOperationBar?.hiddenDownloadButton(isHidden: false)
            NXMainMenuHelper.shared.enableUpload(enable: true)
        }
        
        curNode = folder
        
        fileOperationBar?.showNode(node: curNode)
        
        curShownFiles.removeAllObjects()
        selectedFiles.removeAll()
        refreshDataView(showEmptyImage: false)
        

        CacheMgr.shared.getFilesUnderFolder(folder: curNode!)
        
        if (curNode?.getChildren()?.count == 0){
            // try to retrieve from network
            
            fileTableWaitView.isHidden = false
            self.retrieveFilesFromNetwork(bs: (curNode?.boundService)!, root: curNode!)
        }else{
            refreshData()
            fileTableWaitView.isHidden = true
        }
        
    }
    
    private func switchDataView(){
        
        if currentSelectedItem == .myVault ||
            currentSelectedItem == .deleted ||
            currentSelectedItem == .shared ||
            currentSelectedItem == .favoriteFiles {
            dataMyVaultTableView?.isHidden = false
            
            dataTableView?.isHidden = true
            dataGridView?.isHidden = true
            fileOperationBar?.searchFilesOnly(filesOnly: true)

        }else{
            dataTableView?.isHidden = false
            
            dataMyVaultTableView?.isHidden = true
            dataGridView?.isHidden = true
            fileOperationBar?.searchFilesOnly(filesOnly: false)
            
        }
    }
    
    fileprivate func retrieveFilesFromNetwork(folder: NXFileBase?){
        //folder nil means root folder.
        let node = folder
        if  node == nil {
            self.retrieveFilesUnderRootFromNetwork()
        } else {
           self.retrieveFilesFromNetwork(bs:(node?.boundService!)!, root: node!)
        }
    }
    
    fileprivate func retrieveFilesUnderRootFromNetwork()
    {
        // FIXME: too much update
        guard let currentSelectedItem = currentSelectedItem else {
            return
        }
        if ([.allFiles, .cloudDrive, .myVault, .deleted, .shared, .myDrive] as [RepoNavItem]).contains(currentSelectedItem) {
            if allShownServices.isEmpty == false {
                for i in 0...allShownServices.count - 1
                {
                    let bs = allShownServices[i].boundService
                    let root = allShownServices[i].root
                    
                    self.retrieveFilesFromNetwork(bs: bs, root: root)
                }
            }
        }
        else if currentSelectedItem == .offlineFiles {
            reloadFileList()
        }
        else if currentSelectedItem == .favoriteFiles {
            syncFavFromNetwork()
        }
    }
  
    fileprivate func retrieveFilesFromNetwork(bs: NXBoundService, root: NXFileBase)
    {
        
        if bs.serviceType == ServiceType.kServiceMyVault.rawValue,
            isSharedWithMe == true {
            let service = NXSharedWithMeService()
            service.delegate = self
            service.listFile(with: nil)
            
            return
        }
        
        var service: NXServiceOperation?
        // get data from network
        switch(bs.serviceType)
        {
        case ServiceType.kServiceSkyDrmBox.rawValue:
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            service = NXSkyDrmBox(withUserID: bs.userId, ticket: ticket!)
            break

        case ServiceType.kServiceSharepointOnline.rawValue:
           service = NXSharepointOnline(userId: bs.userId, alias: bs.serviceAlias, accessToken: bs.serviceAccountToken)
            break
        case ServiceType.kServiceMyVault.rawValue:
            service = MyVaultService(withUserID: (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!, ticket: (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!)
            break
        default:
            break
        }
        
        guard let operation = service else {
            return
        }
        operation.setDelegate(delegate: self)
        
        if (operation.getFiles(folder: root)) {
            fileOperationBar?.settingAllFileOperationBtnDisable()
            
            // store service operation
            let item = NXServiceOperationItem(file: root, type: .getlist, service: operation)
            serviceManger.add(element: item)
            
        } else {
            if currentSelectedItem != .allFiles {
                DispatchQueue.main.async {
                    self.waitView.isHidden = true
                    self.fileTableWaitView.isHidden = true
                }
            }
            
            NXCommonUtils.showNotification(title: "SkyDRM", content: NSLocalizedString("LIST_FILE_FAILED", comment: ""))
        }
    }
    
    private func createFileOperationBar(){
        if fileOperationBar == nil {
            let barRect = NSRect(x: navViewWidth, y: self.frame.height - fileOperationBarHeight - self.titleView.bounds.height, width: self.frame.width - navViewWidth, height: fileOperationBarHeight)
            fileOperationBar = NXCommonUtils.createViewFromXib(xibName: "NXFileOperationBar", identifier: "fileOperationBar", frame: barRect, superView: self) as? NXFileOperationBar
            
            fileOperationBar?.barDelegate = self
            fileOperationBar?.doWork(viewMode: .tableView)
        }
        
    }
    
    private func initTitleView() {
        let attribute = [NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#ffffff", alpha: 1.0)]
        homeBtn.attributedTitle = NSAttributedString(string: homeBtn.title, attributes: attribute as [NSAttributedString.Key : Any] )
        titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: attribute as [NSAttributedString.Key : Any])
        
        titleView.wantsLayer = true
        titleView.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
    }
    
    private func createFileView(){
        waitView?.removeFromSuperview()
        
        if dataTableView == nil{
            let frame = NSRect(x: navViewWidth, y: 0, width: self.frame.width - navViewWidth, height: self.frame.height - fileOperationBarHeight - self.titleView.bounds.height)
            dataTableView = NXCommonUtils.createViewFromXib(xibName: "NXFileTableView", identifier: "fileTableView", frame: frame, superView: self) as? NXFileTableView
            
           fileTableWaitView = NXCommonUtils.createWaitingView(superView: dataTableView!)
            
            dataTableView?.dataViewDelegate = self
            
            dataTableView?.doWork()
        }
        
        if dataMyVaultTableView == nil{
            let frame = NSRect(x: navViewWidth, y: 0, width: self.frame.width - navViewWidth, height: self.frame.height - fileOperationBarHeight - self.titleView.bounds.height)
            dataMyVaultTableView = NXCommonUtils.createViewFromXib(xibName: "NXMyVaultFileTableView", identifier: "myVaultFileTableView", frame: frame, superView: self) as? NXMyVaultFileTableView
            
             waitView = NXCommonUtils.createWaitingView(superView: dataMyVaultTableView!)
            
            dataMyVaultTableView?.dataViewDelegate = self
            
            dataMyVaultTableView?.doWork()
        }
    }
    
    fileprivate func showWithTableView(){
        if allShownServices.isEmpty{
            return
        }
        
        let serv = allShownServices[0]
        if serv.boundService.serviceType == ServiceType.kServiceMyVault.rawValue{
            dataMyVaultTableView?.isHidden = false
        }else{
            dataTableView?.isHidden = false
        }
        
        
        dataGridView?.isHidden = true
    }
    
    fileprivate func showWithGridView(){
        dataTableView?.isHidden = true
        dataMyVaultTableView?.isHidden = true
        dataGridView?.isHidden = false
    }
    
    fileprivate func refreshDataView(showEmptyImage: Bool = true){
        // update data view
        
         waitView.isHidden = true
         fileTableWaitView.isHidden = true
        
        if currentSelectedItem == .myVault ||
            currentSelectedItem == .deleted ||
            currentSelectedItem == .shared ||
            currentSelectedItem == .favoriteFiles {
            dataMyVaultTableView?.refreshView(files: curShownFiles, showEmptyImage: showEmptyImage)
            dataMyVaultTableView?.updateData(searchString: fileOperationBar!.searchField.stringValue, showEmptyImage: showEmptyImage)
        }else{
           
            dataTableView?.refreshView(files: curShownFiles, showEmptyImage: showEmptyImage)
            dataTableView?.updateData(searchString: fileOperationBar!.searchField.stringValue, showEmptyImage: showEmptyImage)
            
            dataGridView?.refreshData(files: curShownFiles)
        }
    }
    
    // NXDataViewDelegate
    func folderClicked(folder:NXFileBase?) {
        
        Swift.print("folder clicked")
        fileOperationBar?.searchField.stringValue = ""
        if (folder == nil){
            self.showFileListUnderRoot()
        }else{
            self.showFilesUnderFolder(folder: folder!)
        }
        
        if currentSelectedItem == .allFiles {
            currentSelectedCloudDriveBoundService = folder?.boundService
        }
        
        fileOperationBar?.enableDownloadButton(enable: false)
        NXMainMenuHelper.shared.onDeselectFile()
    }
    
    func fileClicked(file:NXFileBase) {
        if NXFileRenderSupportUtil.renderFileType(fileName: file.name) == NXFileContentType.NOT_SUPPORT {
            if !NXCommonUtils.isGoogleDriveTypeFile(file: file) {
                NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_NOT_SUPPORT_TYPE_RENDER", comment: ""))
                return
            }
        }else if NXFileRenderSupportUtil.renderFileType(fileName: file.name) == NXFileContentType.REMOTEVIEW{
            if ((file as? NXNXLFile) != nil) {
                NXFileRenderManager.shared.viewFile(item: file, renderEventSrc: NXCommonUtils.renderEventSrcType.myvault)
                return
            }else if file.boundService?.serviceType == ServiceType.kServiceSkyDrmBox.rawValue {
                //should filter myDrive
                NXFileRenderManager.shared.viewFile(item: file, renderEventSrc: NXCommonUtils.renderEventSrcType.repository)
                return
            }
        }
        
        if !file.localPath.isEmpty,
            FileManager.default.fileExists(atPath: file.localPath),
            file.localLastModifiedDate == file.lastModifiedDate as Date {
            if ((file as? NXNXLFile) != nil) ||
                file as? NXSharedWithMeFile != nil{
                NXFileRenderManager.shared.viewFile(item: file, renderEventSrc: NXCommonUtils.renderEventSrcType.myvault)
            } else {
                NXFileRenderManager.shared.viewFile(item: file, renderEventSrc: NXCommonUtils.renderEventSrcType.repository)
            }
        }else{
            var runningFiles = [RunningFile]()
            let data = downloadData(file: file, Path: "", fileSource: (file is NXNXLFile || file is NXSharedWithMeFile) ? NXCommonUtils.renderEventSrcType.myvault : NXCommonUtils.renderEventSrcType.repository , needOpen: true)
            
            let result = DownloadUploadMgr.shared.downloadFile(file: file, filePath: nil, delegate: self, data: data, forViewer: true)
            
            if result.0 {
                runningFiles.append(RunningFile(name: file.name, type: .download, id: result.1))
                showProgressViewController(withFiles: runningFiles)
            }
        }
    }
    
    func selectionChanged(files: [NXFileBase]) {
        Swift.print("selectionChanged: \(files)")
        
        selectedFiles = files
        
        if selectedFiles.count == 0 || selectedFiles.count > MAX_DOWNLOADINGFILES_COUNT{
            fileOperationBar?.enableDownloadButton(enable: false)
            NXMainMenuHelper.shared.onDeselectFile()
            return
        }
        
        if let files = files as? [NXSharedWithMeFile] {
            let cannotDownloadFiles = files.filter() {
                file in
                if file.getIsOwner() {
                    return false
                }
                
                if let rights = file.rights {
                    if !rights.contains(.saveAs) {
                        return true
                    }
                }
                
                return false
            }
            if cannotDownloadFiles.isEmpty {
                fileOperationBar?.enableDownloadButton(enable: true)
            } else {
                fileOperationBar?.enableDownloadButton(enable: false)
            }
            
            if files.count > 1 {
                NXMainMenuHelper.shared.settingShareWithMeMenu(with: nil)
            } else {
                if files.first?.getIsOwner() == true {
                    NXMainMenuHelper.shared.settingShareWithMeMenu(with: [.view, .edit, .print, .share, .saveAs, .watermark])
                } else {
                    NXMainMenuHelper.shared.settingShareWithMeMenu(with: files.first?.rights)
                }
            }
            
            return
        }
        
        var hasFolder = false
        var shouldHideOpertation = false
        
        for tmp in selectedFiles{
            if ((tmp as? NXFolder) != nil){
                hasFolder = true
                continue
            }
            if NXCommonUtils.is3rdRepo(node: tmp){
                shouldHideOpertation = true
            }
        }
        
        if hasFolder{
            fileOperationBar?.enableDownloadButton(enable: false)
        }else{
            if currentSelectedItem == .deleted {
                fileOperationBar?.enableDownloadButton(enable: false)
            }
            else if currentSelectedItem == .myVault {
                var bExistDeleted = false
                for file in files {
                    if let myvaultFile = file as? NXNXLFile {
                        if let isDeleted = myvaultFile.isDeleted,
                            isDeleted == true {
                            bExistDeleted = true
                            break
                        }
                    }
                }
                if bExistDeleted {
                    fileOperationBar?.enableDownloadButton(enable: false)
                }
                else {
                    fileOperationBar?.enableDownloadButton(enable: true)
                }
            }
            else if currentSelectedItem == .allFiles{
                if shouldHideOpertation == true{
                    fileOperationBar?.enableDownloadButton(enable: false)
                }else{
                    fileOperationBar?.hiddenDownloadButton(isHidden: false)
                    fileOperationBar?.enableDownloadButton(enable: true)
                }
            }
            else {
                fileOperationBar?.enableDownloadButton(enable: true)
            }
        }
        //update menu
        let is3rdRepo = NXCommonUtils.is3rdRepo(node: selectedFiles[0])
        NXMainMenuHelper.shared.onSelectFileEx(file: selectedFiles[0], is3rdRepo: is3rdRepo)
    }
    
    func fileOperation(type: NXFileOperation, file: NXFileBase?) {
        
        guard let file = file else {
            debugPrint("no file")
            return
        }
        
        Swift.print("file operate: \(type) file name: \(file.name)")
        
        switch type {
        case .openFile:
            if file is NXFolder {
                folderClicked(folder: file)
            }
            else {
                fileClicked(file: file)
            }
        case .protectFile:
            if !NXCommonUtils.isGoogleDriveTypeFile(file: file) && file.size == 0 {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                })
                return
            }
            
            protectFile(file: file)
            break;
        case .shareFile:
            if !NXCommonUtils.isGoogleDriveTypeFile(file: file) && file.size == 0 {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                })
                return
            }
            
            shareFile(file: file)
            break;
        case .downloadFile:
            Swift.print("downloadFile\(file.name)")
            downloadFiles(files: [file])
            
            break;
        case .viewProperty,
             .viewManage,
             .viewDetails:
            
            Swift.print("viewProperty\(file.name)")
            
            let fileInfoViewController = FileInfoViewController(nibName: Constant.fileInfoViewControllerXibName, bundle: nil)
        
            if let nxlFile = file as? NXNXLFile {
                fileInfoViewController.file = nxlFile
            }
            
            
            
            
            // method 1

            // method 2
            self.viewController?.presentAsModalWindow(fileInfoViewController)
            
        case .deleteFile:
            
            self.DeleteFileItemTips(fileBase: file)
            
            Swift.print("deleteFile\(file.name)")
            
            break;
        case .logProperty:
            Swift.print("logProperty\(file.name)")
            
            let vc = NXActivityLogViewController()
            vc.file = file
            
            self.viewController?.presentAsModalWindow(vc)
            
            break;
        case .markFavorite:
            if file.repoId == "" {
                file.repoId = file.boundService?.repoId ?? ""
            }
            
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            let service = NXRepositoryFileService(withUserID: userId!, ticket: ticket!)
            service.delegate = self
            if file.isFavorite {
                service.unmarkFavFile(files: [file])
            } else {
                service.markAsFavFile(files: [file])
            }
            
            break;

        default:
            break
        }
    }
    
    fileprivate func shareFile(file: NXFileBase) {
        if self.shareBtnLock{
            return
        }
        self.shareBtnLock = true
        
        let showShareFileVC = {
            DispatchQueue.main.async {
                self.shareBtnLock = false
                let protectViewController = NXProtectViewController(nibName:  Constant.protectViewContrllerXibName, bundle: nil)
              
                protectViewController.file = file
                protectViewController.fileProtectType = NXFileProtectType.share
                
                self.window?.contentView?.addSubview(MaskView.sharedInstance)
                self.viewController?.presentAsModalWindow(protectViewController)
                protectViewController.doWork()
            }
        }
        
        let fileUrl = URL(fileURLWithPath: file.localPath)
        if FileManager.default.fileExists(atPath: file.localPath),
            let client = NXLoginUser.sharedInstance.nxlClient,
            client.isNXLFile(fileUrl) {
            client.getNXLFileRights(fileUrl, withCompletion: { (rights, isSteward, error) in
                if let error = error {
                    self.shareBtnLock = false
                    if (error as NSError).code == 403 || (error as NSError).code == 404 {
                        self.sendLogToRMS(accessResult: false, file: file, type: .Reshare)
                        NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_NO_RIGHTS", comment: ""))
                    }
                    else {
                        let message = NSLocalizedString(error.localizedDescription, comment: "")
                        NSAlert.showAlert(withMessage: message)
                    }
                }
                else {
                    if rights?.getRight(.NXLRIGHTSHARING) == false, isSteward == false {
                        self.shareBtnLock = false
                        self.sendLogToRMS(accessResult: false, file: file, type: .Reshare)
                        let message = NSLocalizedString("MY_SPACE_NO_RIGHTS", comment: "")
                        NSAlert.showAlert(withMessage: message)
                    }
                    else {
                        showShareFileVC()
                    }
                }
            })

        }
        else {
            showShareFileVC()
        }

    }
    
    fileprivate func protectFile(file: NXFileBase) {
        if let client = NXLoginUser.sharedInstance.nxlClient,
            client.isNXLFile(URL(fileURLWithPath: file.localPath)) {
            NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_CANNOT_PROTECT_NXL", comment: ""))
            return
        }
        
        let protectViewController = NXProtectViewController(nibName:  Constant.protectViewContrllerXibName, bundle: nil)
        protectViewController.file = file
        protectViewController.fileProtectType = NXFileProtectType.protect
        
        self.window?.contentView?.addSubview(MaskView.sharedInstance)
        self.viewController?.presentAsModalWindow(protectViewController)
        protectViewController.doWork()
    }
    
    func deleteFileItemWith(boundService:NXBoundService,fileItem:NXFileBase) -> Bool {
        switch(boundService.serviceType)
        {
        case ServiceType.kServiceSkyDrmBox.rawValue:
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            let service = NXSkyDrmBox(withUserID: boundService.userId, ticket: ticket!)
            service.setDelegate(delegate: self)
            
            return service.deleteFileFolder(file: fileItem)
            
        case ServiceType.kServiceSharepointOnline.rawValue:
            let service = NXSharepointOnline(userId: boundService.userId, alias: boundService.serviceAlias, accessToken: boundService.serviceAccountToken)
            service.setDelegate(delegate: self)
            
            return service.deleteFileFolder(file: fileItem)
            
        case ServiceType.kServiceMyVault.rawValue:
            let service = MyVaultService(withUserID: (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!, ticket: (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)!)
            service.delegate = self
            currentSeletedMyVaultFileForDelete = fileItem as? NXNXLFile
            
            return service.deleteFileFolder(file: fileItem)
            
        default:
            break
        }
        return false
    }
    
    func createFolderWith(boundService:NXBoundService,folderName:String,parentFolder:NXFileBase) -> Bool{
        
        if boundService.serviceType != ServiceType.kServiceGoogleDrive.rawValue  {
            if createTheSameFolderNameConflictTips(folderName:folderName) == false
            {
                return false
            }
        }
        
        switch(boundService.serviceType)
        {
        case ServiceType.kServiceSkyDrmBox.rawValue:
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            let service = NXSkyDrmBox(withUserID: boundService.userId, ticket: ticket!)
            service.setDelegate(delegate: self)

            return service.addFolder(folderName: folderName, parentFolder: parentFolder)
            
        case ServiceType.kServiceSharepointOnline.rawValue:
            let service = NXSharepointOnline(userId: boundService.userId, alias: boundService.serviceAlias, accessToken: boundService.serviceAccountToken)
            service.setDelegate(delegate: self)
            
            return service.addFolder(folderName: folderName, parentFolder: parentFolder)
            
        case ServiceType.kServiceMyVault.rawValue: break
            
        default:
            break
        }
        return false
    }
    
    func createTheSameFolderNameConflictTips(folderName:String) -> Bool
    {
        for item in curShownFiles {
            if (item as? NXFolder)?.name.caseInsensitiveCompare(folderName) == .orderedSame {
                NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_FOLDER_NAME_EXISTED", comment: ""));
                return false
            }
        }
        return true
    }
    
    func createTheSameFileNameConflictTips(fileName:String) -> Bool
    {
        for item in curShownFiles {
            if (item as? NXFile)?.name.caseInsensitiveCompare(fileName) == .orderedSame {
                NSAlert.showAlert(withMessage: NSLocalizedString("MY_SPACE_FILE_NAME_EXISTED", comment: ""));
                return false
            }
        }
        return true
    }
    
    fileprivate func sendLogToRMS(accessResult:Bool,file:NXFileBase?, type: OperationEnum, filePath:String? = nil, needDelete:Bool = false){
        let fileURL = filePath == nil ? URL(fileURLWithPath: (file?.localPath)!) : URL(fileURLWithPath: (filePath)!)
        NXLoginUser.sharedInstance.nxlClient?.getStewardForNXLFile(fileURL, withCompletion: { (steward, duid, error) in
            if needDelete {
                NXCommonUtils.removeTempFileAndFolder(tempPath: fileURL)
            }
            
            let putModel = NXPutActivityLogInfoRequestModel()
            
            let time:TimeInterval = NSDate().timeIntervalSince1970 ;
            let accessTime = Int(time*1000)
            let duid = file?.getNXLID() ?? duid
            putModel.duid = duid ?? ""
            putModel.owner = steward ?? ""
            putModel.operation = type.rawValue
            putModel.repositoryId = file?.boundService?.repoId ?? " "
            putModel.filePathId = " "
            putModel.fileName = file?.name
            putModel.filePath = file?.fullServicePath
            putModel.activityData = " "
            putModel.accessTime = accessTime
            let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
            putModel.userID = userId
            
            if accessResult == false {
                putModel.accessResult = 0
            }else{
                putModel.accessResult = 1
            }
            
            self.logService?.putActivityLogInfoWith(activityLogInfoRequestModel: putModel)
        })
    }
    
    fileprivate func isNodeChange(with servicePath: String?) -> Bool {
        guard let servicePath = servicePath else {
            return false
        }
        
        var found = false
        if (self.curNode == nil)
        {
            for tmp in self.allShownServices{
                let root = tmp.root
                
                if (servicePath == root.fullServicePath),
                    self.isSharedWithMe == isSharedWithMe
                {
                    found = true
                    break
                }
            }
        } else {
            if (servicePath == self.curNode?.fullServicePath)
            {
                found = true
            }
        }
        
        return !found
    }
    
    fileprivate func updateCoreData(servicePath: String?, favFile: NXRepoFavFileItem?, isSharedWithMe: Bool = false) {
        saveToCoreData(favFile: favFile)
        
    }
    
    //MARK: NXServiceOperationDelegate
    func getFilesFinished(folder: NXFileBase, files: NSArray?, error: NSError?) {
        DispatchQueue.main.async {
            Swift.print("getFilesFinished was called, servicePath: \(folder.fullServicePath) error: \(String(describing: error))")
            
            let item = NXServiceOperationItem(file: folder, type: .getlist, service: nil)
            _ = self.serviceManger.remove(element: item)
            
            if self.isNodeChange(with: folder.fullServicePath) {
                Swift.print("node was changed, this data doesn't make sense, doesn't need to do anything")
                return
            }
            
            if self.currentSelectedItem == .allFiles {
                if self.serviceManger.isEmpty() {
                    self.fileOperationBar?.settingFileOperationBtnStatus(with: self.currentSelectedItem!)
                }
            } else {
                self.fileOperationBar?.settingFileOperationBtnStatus(with: self.currentSelectedItem!)
            }
            
            // error handler
            if (error != nil)
            {
                if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED.rawValue || error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_AUTHFAILED.rawValue
                {
                    self.cloudDriveExpiredTips()
                }
                
                if self.currentSelectedItem == .allFiles {
                    if self.serviceManger.isEmpty() {
                        self.refreshData()
                    }
                } else {
                    self.waitView.isHidden = true
                    self.fileTableWaitView.isHidden = true
                }
                
                return
            }
            
            if let file = files?.firstObject as? NXFileBase,
                file.boundService?.serviceType == ServiceType.kServiceSkyDrmBox.rawValue ||
                    file.boundService?.serviceType == ServiceType.kServiceMyVault.rawValue {
                let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId
                let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
                let service = NXRepositoryFileService(withUserID: userId!, ticket: ticket!)
                service.delegate = self
                service.getFavFile(repoId: (file.boundService?.repoId)!, lastModified: nil, customData: folder.fullServicePath)
                
                let item = NXFavOperationItem(repoId: (file.boundService?.repoId)!, service: service)
                self.serviceManger.add(element: item)
                
            } else {
                
                
                self.updateCoreData(servicePath: folder.fullServicePath, favFile: nil)
                if self.currentSelectedItem == .allFiles {
                    if self.serviceManger.isEmpty() {
                        self.refreshData()
                    }
                } else {
                    self.refreshData()
                }
                
            }
        }
        
    }
    
    private func changeShowFiles() {
        if isSharedWithMe {
            curShownFiles.removeAllObjects()
            let files = DBSharedWithMeFileHandler.shared.getAll()
            curShownFiles.addObjects(from: files)
        }
    }
    
    private func fetchFilesForCurrentNode()
    {
        curShownFiles.removeAllObjects()
        
        if (curNode == nil)
        {
            for tmp in allShownServices
            {
                let children = tmp.root.getChildren()
                curShownFiles.addObjects(from: children as! [Any])
            }
        }else{
            if let children = curNode?.getChildren() as? [Any] {
                curShownFiles.addObjects(from: children)
            }
        }
        
    }
    
    private func saveToCoreData(favFile: NXRepoFavFileItem?) {
        if let currentFolder = curNode {
            let children = currentFolder.getChildren()
            
            // save isFavorite
            if let markFiles = favFile?.markFiles,
                let children = children as? [NXFileBase] {
                for file in children {
                    let updateFiles = markFiles.filter() { file.fullServicePath == $0.pathId }
                    if !updateFiles.isEmpty {
                        file.isFavorite = true
                    } else {
                        file.isFavorite = false
                    }
                }
            }
            
            if CacheMgr.shared.saveFilesUnderFolder(folder: currentFolder, files: children) {
                CacheMgr.shared.getFilesUnderFolder(folder: currentFolder)
            } else {
                Swift.print("\(currentFolder.name) folder failed to save to core data")
            }
            
        } else { // root
            for service in allShownServices {
                let bs = service.boundService
                let root = service.root
                let children = root.getChildren()
                
                // save isFavorite
                if let markFiles = favFile?.markFiles,
                    let children = children as? [NXFileBase] {
                    for file in children {
                        let updateFiles = markFiles.filter() { file.fullServicePath == $0.pathId }
                        if !updateFiles.isEmpty {
                            file.isFavorite = true
                        } else {
                            file.isFavorite = false
                        }
                    }
                }
                
                if CacheMgr.shared.saveFilesUnderRoot(bs: bs, files: children) {
                    CacheMgr.shared.getFilesUnderRoot(bs: bs, root: root)
                } else {
                    Swift.print("\(bs.serviceAlias) root failed to save to core data")
                }

            }
            
        }
        
    }
    
    fileprivate func refreshData()
    {
        if allShownServices.first?.boundService.serviceType == ServiceType.kServiceMyVault.rawValue,
            isSharedWithMe {
            changeShowFiles()
        } else {
            fetchFilesForCurrentNode()
        }
        
        selectedFiles.removeAll()
        
        if curNode == nil && allShownServices.count > 1{
            fileOperationBar?.enableUploadButton(enable: false)
            fileOperationBar?.enableCreateFolderButton(enable: false)
            NXMainMenuHelper.shared.enableUpload(enable: false)
        }else{
            fileOperationBar?.enableUploadButton(enable: true)
            fileOperationBar?.enableCreateFolderButton(enable: true)
            if let fileOperationBar = fileOperationBar {
                NXMainMenuHelper.shared.enableUpload(enable: !fileOperationBar.uploadFileButton.isHidden)
            }
        }

        refreshDataView()
    }
    
    func cloudDriveExpiredTips()
    {
        NSAlert.showAlert(withMessage: NSLocalizedString("ERROR_CLOUDDRIVE_EXPIRED_OR_UNAUTHORIZED", comment: ""), informativeText: "", dismissClosure: { _ in
            DispatchQueue.main.async {
                if let bs = self.currentSelectedCloudDriveBoundService {
                    let repo = NXRMCRepoItem(from: bs)
                    NXAuthMgr.shared.remove(item: repo)
                }
                if let bs = self.currentSelectedCloudDriveBoundService,
                    let currentBoundService = DBBoundServiceHandler.shared.fetchBoundService(with:bs.repoId, type: ServiceType(rawValue: bs.serviceType)!) {
                    currentBoundService.service_is_authed = false
                    let temp = NXBoundService()
                    DBBoundServiceHandler.formatNXBoundService(src: currentBoundService, target: temp)
                    if DBBoundServiceHandler.shared.updateBoundService(item: temp) == true {
                        // should go to home page
                        self.navView.navOutlineView.selectRowIndexes(NSIndexSet(index: 2) as IndexSet, byExtendingSelection: false)
                        self.navClicked(item: RepoNavItem.favoriteFiles, userData: nil)
                        
                        self.delegate?.shouldGoToHomePage()
                    }
                }
            }
        })
    }
    
    struct Constant {
        static let progressTreeViewControllerXibName = "NXProgressTreeViewController"
        static let fileInfoViewControllerXibName = "FileInfoViewController"
        static let protectViewContrllerXibName = "NXProtectViewController"
        
    }
 
    var progressTreeViewController: NXProgressTreeViewController?
    
    fileprivate func reloadFileList() {
        guard let current = currentSelectedItem else {
            return
        }
        
        switch current {
        case .favoriteFiles:
            
            curShownFiles.removeAllObjects()
            let files = CacheMgr.shared.getSkyDrmFavorite()
            curShownFiles.addObjects(from: files)
            
        case .myVault:
            curShownFiles.removeAllObjects()
            let myVaultFiles = DBMyVaultFileHandler.shared.getAll()
            curShownFiles.addObjects(from: myVaultFiles)
            
        case .deleted:
            curShownFiles.removeAllObjects()
            let myVaultFiles = DBMyVaultFileHandler.shared.getAll()
            let deletes = myVaultFiles.filter() { $0.isDeleted == true }
            curShownFiles.addObjects(from: deletes)
            
        case .shared:
            curShownFiles.removeAllObjects()
            let myVaultFiles = DBMyVaultFileHandler.shared.getAll()
            let shares = myVaultFiles.filter() { $0.isShared == true }
            curShownFiles.addObjects(from: shares)
        
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.refreshDataView()
        }
    }
   
    func syncFavFromNetwork() {
        let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId
        let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
        let service = NXRepositoryFileService(withUserID: userId!, ticket: ticket!)
        service.delegate = self
        service.getAllFavFiles()
    }
    
    @IBAction func backHome(_ sender: Any) {
        switchFileList()
        delegate?.shouldGoToHomePage()
    }
    
    @IBAction func showDropDownList(_ sender: Any) {
        
        delegate?.showDropDownList()
    }
    
    func switchFileList() {
        // cancel all
        _ = serviceManger.cancelAll()
        fileOperationBar?.settingFileOperationBtnStatus(with: currentSelectedItem!)
    }
}

extension NXFileListView: NXRepoNavDelegate{
    func navClicked(item: RepoNavItem, userData: Any?){
        Swift.print("repo nav callback: \(item)")
        currentSelectedItem = item
        fileOperationBar?.searchField.stringValue = ""
        currentSelectedCloudDriveBoundService = nil
        currentSelectedCloudDriveFolder = nil
        
        fileOperationBar?.hiddenCreateFolderButton(isHidden: false)
        fileOperationBar?.enableCreateFolderButton(enable: false)
        fileOperationBar?.hiddenSelectMenuButton(isHidden: true)
        fileOperationBar?.hiddenUploadButton(isHidden: false)
        fileOperationBar?.hiddenDownloadButton(isHidden: false)
        
        fileOperationBar?.enableUploadButton(enable: false)
        fileOperationBar?.enableDownloadButton(enable: false)
        NXMainMenuHelper.shared.onDeselectFile()
        NXMainMenuHelper.shared.enableUpload(enable: false)
        
        fileOperationBar?.hiddenSharedSegment(isHidden: true)
        
        dataTableView?.shouldHiddenSortByRepo = false
        dataMyVaultTableView?.isSharedWithMe = false
        dataMyVaultTableView?.isFavorite = false
        
        settingFileOperationBar(with: item)
        
        fileOperationBar?.settingFileOperationBtnStatus(with: item)
        
        switch item {
        case .allFiles:
            
            showType = .kTypeNormal
            allShownServices.removeAll()
            let authBS = allBoundServices.filter() { $0.boundService.serviceIsAuthed == true }
            allShownServices.append(contentsOf: authBS)
            fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_ALLFILES", comment: "")
            
            if allShownServices.count == 1 {
                currentSelectedCloudDriveBoundService = allShownServices[0].boundService
                currentSelectedCloudDriveFolder = allShownServices[0].root
            }
            
            showFileListUnderRoot()
            
            break
        case .myDrive:
            showType = .kTypeNormal
            
            dataTableView?.shouldHiddenSortByRepo = true
            guard let service = userData as? (boundService:NXBoundService, root: NXFileBase) else {
                debugPrint("fail to get service")
                return
            }
            
            showBoundService(service: service)
            

            break
        case .cloudDrive:
            showType = .kTypeNormal
            
            dataTableView?.shouldHiddenSortByRepo = true
            guard let service = userData as? (boundService:NXBoundService, root: NXFileBase) else {
                debugPrint("fail to get service")
                return
            }
            if service.boundService.serviceType != ServiceType.kServiceSkyDrmBox.rawValue{
                fileOperationBar?.hiddenCreateFolderButton(isHidden: true)
                fileOperationBar?.hiddenUploadButton(isHidden: true)
                fileOperationBar?.hiddenDownloadButton(isHidden: true)
                NXMainMenuHelper.shared.enableUpload(enable: false)
            }
            if service.boundService.serviceIsAuthed {
                showBoundService(service: service)
            } else{
                cleanTable()
                authBoundService(service: service)
            }
            
            
            break
        case .favoriteFiles:
            
            dataMyVaultTableView?.isFavorite = true
            
            fileOperationBar?.hiddenCreateFolderButton(isHidden: true)
            fileOperationBar?.hiddenUploadButton(isHidden: true)
            
            showType = .kTypeFavorite
            

            fileOperationBar?.enableUploadButton(enable: true)
            if let fileOperationBar = fileOperationBar {
                NXMainMenuHelper.shared.enableUpload(enable: !fileOperationBar.isHidden)
            }
            allShownServices.removeAll()
            fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_FAVORITEFILES", comment: "")
            showFileList()
            
        case .myVault,
             .deleted,
             .shared:
            
            switch item {
            case .myVault:
                fileOperationBar?.hiddenSelectMenuButton(isHidden: false)
                dataMyVaultTableView?.currentType = .allType
                
                fileOperationBar?.rootNodeName = NSLocalizedString("STRING_MYVAULT", comment: "")
                
            case .deleted:
                dataMyVaultTableView?.currentType = .deleted
                
                fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_DELETEDFILES", comment: "")
                
            case .shared:
                fileOperationBar?.hiddenSharedSegment(isHidden: false)
                fileOperationBar?.resetSharedSegment()
                dataMyVaultTableView?.isSharedWithMe = true
                
                dataMyVaultTableView?.currentType = .activeShare
                fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_SHAREDFILES", comment: "")
                
            default:
                break
            }
            
            fileOperationBar?.hiddenCreateFolderButton(isHidden: true)
            fileOperationBar?.hiddenUploadButton(isHidden: true)
            NXMainMenuHelper.shared.enableUpload(enable: false)
            
            showType = .kTypeMyVault
            let myVaults = DBBoundServiceHandler.shared.fetchBoundService(withType: ServiceType.kServiceMyVault)
            guard myVaults.count == 1, let myValue = myVaults.first else {
                return
            }
            let root = NXFolder()
            root.isRoot = true
            root.boundService = myValue
            root.fullPath = "/"
            root.fullServicePath = "/"
            
            allShownServices.removeAll()
            allShownServices.append((myValue, root))
            showFileListUnderRoot()
            
        default:
            break
        }
    }
    
    private func settingFileOperationBar(with navType: RepoNavItem) {
        
        fileOperationBar?.rootNodeType = navType
        // path
        switch navType {
        case .deleted:
            fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_DELETEDFILES", comment: "")
        case .shared:
            fileOperationBar?.rootNodeName = NSLocalizedString("REPO_STRING_SHAREDFILES", comment: "")
        default:
            break
        }
        // button status
        switch navType {
        case .deleted,
             .shared:
            fileOperationBar?.hiddenCreateFolderButton(isHidden: true)
            fileOperationBar?.hiddenSelectMenuButton(isHidden: true)
            fileOperationBar?.hiddenRefreshButton(isHidden: false)
            fileOperationBar?.hiddenUploadButton(isHidden: true)
            fileOperationBar?.enableDownloadButton(enable: false)
            NXMainMenuHelper.shared.onDeselectFile()
            NXMainMenuHelper.shared.enableUpload(enable: false)
            
        default:
            break
        }
    }
    
    private func authBoundService(service: (boundService: NXBoundService, root: NXFileBase)) {
        let item = NXRMCRepoItem(from: service.boundService)
        if item.type == .kServiceOneDrive,
            NXCommonUtils.loadOnedriveState() {
            NSAlert.showAlert(withMessage: String(format: NSLocalizedString("REPOSITORY_ADD_ALERT_OTHER_ACCOUNT", comment: ""), "OneDrive"))
            return
        }
        guard let window = self.window else {
            return
        }
        
        currentSelectedCloudDriveBoundService = service.boundService
        currentSelectedCloudDriveFolder = service.root
        
        NXAuthMgr.shared.add(item: item, window: window)
        NXAuthMgr.shared.delegate = self
        setClose(isClosable: NXAuthMgr.shared.supportCancel())
        startAnimation()
    }
    
    fileprivate func showBoundService(service: (boundService: NXBoundService, root: NXFileBase)) {
        allShownServices.removeAll()
        allShownServices.append(service)
        currentSelectedCloudDriveBoundService = service.boundService
        currentSelectedCloudDriveFolder = service.root
        fileOperationBar?.enableCreateFolderButton(enable: true)
        if let serviceAlias = currentSelectedCloudDriveBoundService?.serviceAlias {
            fileOperationBar?.rootNodeName = serviceAlias
        }
        showFileListUnderRoot()
    }
    
    private func cleanTable() {
        // clean data view first
        curShownFiles.removeAllObjects()
        selectedFiles.removeAll()
        refreshDataView()
    }
}

extension NXFileListView: NXFileOperationBarDelegate{
    func fileOperationBarDelegate(type: NXFileOperationType, userData: Any?){
        switch type {
        case .tableView:
            showWithTableView()
            break
        case .gridView:
            showWithGridView()
            break
        case .search:
            selectedFiles.removeAll()
            fileOperationBar?.enableDownloadButton(enable: false)
            NXMainMenuHelper.shared.onDeselectFile()
            self.searchFileOrFolderWithCurrentSelectedItem(item: currentSelectedItem!, searchString: userData as! String)
            break
            
        case .pathNodeClicked:
            
            if let fullPath = userData as? String {
                if fullPath == "/" {
                    if currentSelectedItem == .favoriteFiles {
                        showFileList()
                    } else {
                        showFileListUnderRoot()
                    }
                    
                } else {
                    if let repoId = currentSelectedCloudDriveBoundService?.repoId,
                        let type = ServiceType(rawValue: (currentSelectedCloudDriveBoundService?.serviceType)!),
                        let fileBase = DBFileBaseHandler.shared.fetchFileBase(with: repoId, fullPath: fullPath, type: type) {
                        let folder = NXFolder()
                        DBFileBaseHandler.formatNXFileBase(src: fileBase, target: folder)
                        showFilesUnderFolder(folder: folder)
                    }
                }
                
                break
            }
        
        case .refreshClicked:
            
            fileTableWaitView.isHidden = false
            waitView.isHidden = false
            
            if curNode == nil{
                self.retrieveFilesUnderRootFromNetwork()
            }else{

                self.retrieveFilesFromNetwork(bs: (curNode?.boundService)!, root: curNode!)
            }
            break

        case .seeViewedBack:
            seeViewed(isBack: true)
            
        case .seeViewedForward:
            seeViewed(isBack: false)
            
        case .uploadFile:
            uploadLocalFile()
            break
        case .downloadFile:
            downloadFiles(files:selectedFiles)
            break
        case .createFolder:
            
            let vc = NXCreateFolderPopViewController()
            vc.createFolderDelegate = self
            NSApplication.shared.keyWindow?.windowController?.contentViewController?.presentAsModalWindow(vc)
            break
        case .selectMenuItem:
            
            fileOperationBar?.searchField.stringValue = ""
            dataMyVaultTableView?.updateData(searchString: "")
            dataMyVaultTableView?.operationBarMenuItemSelected(tittle: userData as! String)
            
            break
            
        case .changeSharedSegmentValue:
            fileOperationBar?.searchField.stringValue = ""
            dataMyVaultTableView?.updateData(searchString: "")
            
            if let isSharedWithMe = userData as? Bool {
                dataMyVaultTableView?.isSharedWithMe = isSharedWithMe
            }
            
            showFileListUnderRoot()
        }
    }

    private func seeViewed(isBack: Bool) {
        guard let viewedHistory = viewedHistory else {
            return
        }
        
        var isSuccess = false
        repeat {
            var canMove = true
            if isBack {
                canMove = viewedHistory.moveBack()
            } else {
                canMove = viewedHistory.moveForward()
            }
            if !canMove {
                break
            }
            isSuccess = displayViewed()
            
        } while isSuccess == false
        
    }
    
    private func displayViewed() -> Bool {
        guard let viewedHistory = viewedHistory else {
            return false
        }
        
        let previousPath = viewedHistory.getCurrentViewedPath()
        
        guard let pathId = previousPath.pathId else {
            if let item = navView.getMenuItem(with: previousPath.navName, navType: previousPath.navType) {
                if navView.isItemSelected(item: item) {
                    folderClicked(folder: nil)
                } else {
                    navView.selectItem(item: item)
                }
                
                return true
            }
            return false
        }
        
        if let fileBase = DBFileBaseHandler.shared.fetchFileBase(with: pathId) {
            let folder = NXFolder()
            DBFileBaseHandler.formatNXFileBase(src: fileBase, target: folder)
            if let item = navView.getMenuItem(with: previousPath.navName, navType: previousPath.navType) {
                if navView.isItemSelected(item: item) {
                    folderClicked(folder: folder)
                } else {
                    navView.selectItem(item: item)
                    folderClicked(folder: folder)
                }
                return true
            }
            return false
        }
        
        return false
    }
    
    private func uploadLocalFile(){
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        
        let mainWindow = NXCommonUtils.getMainWindow()
        openPanel.beginSheetModal(for: mainWindow) { (result) in
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
                
                let fileName = URL(fileURLWithPath: (src?.path)!).lastPathComponent
                if self.createTheSameFileNameConflictTips(fileName:fileName) == false
                {
                    return
                }
                
                let storyBoard = NSStoryboard(name: "Main", bundle: nil) as NSStoryboard
                let uploadVC = storyBoard.instantiateController(withIdentifier:"uploadVC") as! NXUploadVC
            
                
                uploadVC.srcFilePath = src?.path
                
                var curFolder = self.curNode
                if curFolder == nil{
                    curFolder = self.allShownServices[0].root
                }
                
                
                
                uploadVC.destFolder = curFolder
                
                uploadVC.delegate = self
                
                self.viewController?.presentAsModalWindow(uploadVC)
            }
        }

    }
    
    fileprivate func downloadFiles(files:[NXFileBase]){
        let savePanel = NSOpenPanel()
        savePanel.canChooseFiles = false
        savePanel.canChooseDirectories = true
        savePanel.beginSheetModal(for: NXCommonUtils.getMainWindow()) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let dest = savePanel.url else {
                    return
                }
                self.fileTableWaitView.isHidden = false
                self.downloadURL = dest
                self.downloadFiles.removeAll()
                
                if files is [NXSharedWithMeFile] {
                    self.downloadFiles.append(contentsOf: files)
                    self.fileTableWaitView.isHidden = true
                    self.beginDownload(files: self.downloadFiles, dstUrl: self.downloadURL)
                    return
                }
                
                var nxlFiles = [NXFileBase]()
                for file in files {
                    if file is NXNXLFile {
                        self.downloadFiles.append(file)
                    }
                    else if NXCommonUtils.isNXLFile(path: (file.localPath != "") ? file.localPath : file.name) {
                        nxlFiles.append(file)
                    }
                    else {
                        self.downloadFiles.append(file)
                    }
                }
                self.checkedDownloadFiles = self.checkDownloadRights(files: nxlFiles)
                if self.checkedDownloadFiles.isEmpty {
                    self.fileTableWaitView.isHidden = true
                    self.beginDownload(files: self.downloadFiles, dstUrl: self.downloadURL)
                }
            }
        }
    }
    
    fileprivate func checkDownloadRights(files: [NXFileBase]) -> [NXFileBase] {
        var retFiles = [NXFileBase]()
        for file in files {
            let result = DownloadUploadMgr.shared.rangeDownloadFile(file: file, length: 0x4000, delegate: self, data: rangeDownloadData(file: file, cachePath: ""))
            if result.0 {
                retFiles.append(file)
            }
        }
        return retFiles
    }
    
    fileprivate func beginDownload(files: [NXFileBase], dstUrl: URL) {
        var runningFiles = [RunningFile]()
        
        for file in files {
            let data = downloadData(file: file, Path: "", fileSource: .other, needOpen: false)
            let result = DownloadUploadMgr.shared.downloadFile(file: file, filePath: dstUrl.path, delegate: self, data: data)
            
            if result.0 {
                runningFiles.append(RunningFile(name: file.name, type: .download, id: result.1))
            }
        }
        
        self.showProgressViewController(withFiles: runningFiles)
    }
    
    fileprivate func showProgressViewController(withFiles files: [RunningFile]) {
        guard files.count != 0 else {
            return
        }
        
        // 1. progress view
        let progressViewController = NXProgressTreeViewController(nibName:  Constant.progressTreeViewControllerXibName, bundle: nil)
      
     
        
        self.progressTreeViewController = progressViewController
        progressViewController.delegate = self
        
        // 2. set viewcontroller
        progressViewController.setDoing(doing: files)
        
        // 3. present progress view
        DispatchQueue.main.async {
            self.viewController?.presentAsModalWindow(progressViewController)
        }
    }
}

extension NXFileListView {
    
    func searchFileOrFolderWithCurrentSelectedItem(item:RepoNavItem, searchString:String) {
        switch item {
        case .allFiles:
              dataTableView?.updateData(searchString:searchString)
        
            break
        case .cloudDrive, .myDrive:
             dataTableView?.updateData(searchString:searchString)
             
            break
        case .myVault,
             .deleted,
             .shared:
            dataMyVaultTableView?.updateData(searchString: searchString)
            
            break
        case .offlineFiles:
            dataTableView?.updateData(searchString: searchString)
            break
        case .favoriteFiles:
            dataMyVaultTableView?.updateData(searchString: searchString)
            
            break
        default:
            break
        }
    }
    
    func deleteFileFolderFinished(servicePath: String?, error: NSError?)
    {
        // Assume servicePath never nil
        guard let pathId = servicePath else {
            return
        }

        if error != nil {
            if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED.rawValue || error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_AUTHFAILED.rawValue
            {
                cloudDriveExpiredTips()
            }
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(String(format: NSLocalizedString("MY_SPACE_DELETE_FAILED", comment: ""), URL(fileURLWithPath: servicePath!).lastPathComponent))
            }
            
            // log myVault
            if let myVaultFile = DBMyVaultFileHandler.shared.fetchMyVaultFile(with: pathId) {
                let nxMyVaultFile = NXNXLFile()
                DBMyVaultFileHandler.format(from: myVaultFile, to: nxMyVaultFile)
                if nxMyVaultFile.isRevoked == false {
                    self.sendLogToRMS(accessResult: false, file: nxMyVaultFile, type: .Revoke)
                }
            }
            return
        }
        DispatchQueue.main.async {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("MY_SPACE_DELETE_SUCCESS", comment: ""))
        }
        
        if let myVaultFile = DBMyVaultFileHandler.shared.fetchMyVaultFile(with: pathId) {
            myVaultFile.is_Deleted = true
            _ = DBMyVaultFileHandler.shared.updateAll()
            
        } else {
            _ = DBFileBaseHandler.shared.deleteFileBase(with: pathId)
        }
        
        DispatchQueue.main.async {
            // TODO: update view
            if let curNode = self.curNode  {
                self.showFilesUnderFolder(folder: curNode)
            } else {
                self.showFileListUnderRoot()
            }
            
        }
    }
    
    func addFolderFinished(folderName: String?, parentServicePath: String?, error: NSError?)
    {
        if (error != nil)  {
            if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED.rawValue || error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_AUTHFAILED.rawValue
            {
                cloudDriveExpiredTips()
            }
            DispatchQueue.main.async {
                // add folder failed
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_FAILED", comment: ""))
            }
        }
        else
        {
            DispatchQueue.main.async {
                // need to check if parent node changed or not, if changed, don't need to do anything
           
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_SUCCESS", comment: ""))
                
                if self.curNode == nil{
                    self.retrieveFilesUnderRootFromNetwork()
                    if self.allShownServices.count == 1 {
                        let bs = self.allShownServices[0].boundService
                        if bs.serviceType == ServiceType.kServiceSkyDrmBox.rawValue ||
                            bs.serviceType == ServiceType.kServiceMyVault.rawValue {
                            self.updateMySpaceStorageUI()
                        }
                    }

                }else{
                    self.retrieveFilesFromNetwork(bs: (self.curNode?.boundService)!, root: self.curNode!)
                    if let boundService = self.curNode?.boundService {
                        if boundService.serviceType == ServiceType.kServiceSkyDrmBox.rawValue ||
                            boundService.serviceType == ServiceType.kServiceMyVault.rawValue {
                            self.updateMySpaceStorageUI()
                        }
                    }
                }
            }
        }
    }
}

extension NXFileListView: NXCreateFolderPopViewDelegate{
    func createFolderPopViewFinished(type: NXCreateFolderEventType, newFolderName: String){
        switch type {
        case .cancelButtonClicked:
            // has nothing to do
            break
        case .createButtonClicked:
            
            if newFolderName.isEmpty{
                // // has nothing to do
            }
            else
            {
                if curNode != nil {
                    
                    
                    guard createFolderWith(boundService: currentSelectedCloudDriveBoundService ?? (curNode?.boundService)!, folderName: newFolderName, parentFolder: curNode!) else
                    {
                        NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_FAILED", comment: ""))
                        return
                    }
                }
                else
                {
                    guard createFolderWith(boundService: currentSelectedCloudDriveBoundService!, folderName: newFolderName, parentFolder: currentSelectedCloudDriveFolder!) else
                    {
                    NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_FAILED", comment: ""))
                        return
                    }
                }
            }
             break
        }
    }
}

extension NXFileListView: NXUploadVCDelegate {
    func upload(files: [(src: String, dest:NXFileBase, originalFileName: String?, fileSource: NXFileBase?)]) {
        var info = [(name: String, id: Int)]()
        
        for file in files {
            let fileName = (file.originalFileName == nil) ? URL(fileURLWithPath: file.src).lastPathComponent : file.originalFileName
            let data = uploadData(srcPath: file.src, bTempNxlFile: (file.originalFileName == nil) ? false : true)
            
            let result = DownloadUploadMgr.shared.uploadFile(filename: fileName!, folder: file.dest, srcPath: file.src, fileSource: file.fileSource, delegate: self, data: data)
            
            if result.0 {
                if file.originalFileName == nil {
                    info.append((fileName!, result.1))
                } else {
                    info.append((URL(fileURLWithPath: file.src).lastPathComponent, result.1))
                }
            }
        }
                
        showProgressTreeViewController(info: info)
    }
    
    func uploadWithoutProtection(src: String, dest: NXFileBase) {
        let fileName = URL(fileURLWithPath: src).lastPathComponent
        let data = uploadData(srcPath: src, bTempNxlFile: false)
        
        let result = DownloadUploadMgr.shared.uploadFile(filename: fileName, folder: dest, srcPath: src, fileSource: nil, delegate: self, data: data)
        
        if result.0 {
            showProgressTreeViewController(info: [(name: fileName, result.1)])
        }
    }
    
    private func showProgressTreeViewController(info: [(name: String, id: Int)]) {
        var runningFiles = [RunningFile]()
        for file in info {
            let runningFile = RunningFile(name: file.name, type: .upload, id: file.id)
            runningFiles.append(runningFile)
        }
        
        showProgressViewController(withFiles: runningFiles)
    }
}

extension NXFileListView: DownloadUploadMgrDelegate {
    
    func updateProgress(id: Int, data: Any?, progress: Float) {
        progressTreeViewController?.updateProgress(id: id, progress: Double(progress))
    }
    
    func downloadUploadFinished(id: Int, data: Any?, error: NSError?) {
        DispatchQueue.main.async {
            if let data = data as? downloadData {
                // send log
                if error == nil {
                    if (data.file is NXSharedWithMeFile) == false,
                        NXCommonUtils.isNXLFile(path: (data.file.localPath != "") ? data.file.localPath : data.file.name), !data.needOpen {
                        self.sendLogToRMS(accessResult: true, file: data.file, type: .Download, filePath: data.Path)
                    }
                }
                
                var content = "Download file: " + data.file.name + " successfully"
                if let error = error{
                    if error.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                        content = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                    }else {
                        if nil != data.file as? NXSharedWithMeFile,
                            1 == error.code {
                            content = NSLocalizedString("DOWNLOAD_SHAREWITHME_FILE_FAILED", comment:"")
                        } else {
                            content = NSLocalizedString("DOWNLOAD_FILE_FAILED", comment:"")
                        }
                    }
                }
                NXCommonUtils.showNotification(title:"SkyDRM", content:content)
                let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
                self.progressTreeViewController?.setStatus(id: id, status: status)
                
                if error != nil {
                    try? FileManager.default.removeItem(atPath: data.Path)
                } else {
                    if data.needOpen {
                        NXFileRenderManager.shared.viewFile(item: data.file, renderEventSrc: data.fileSource)
                    }
                }
            } else if let data = data as? uploadData {
                let url = URL(fileURLWithPath: data.srcPath)
                var content = NSLocalizedString("UPLOAD_FILE_SUCCESS", comment: "")
              
                if error != nil {
                    if error!.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue  {
                        content = "Upload file: " + url.lastPathComponent + " failed:\n" + NSLocalizedString("UploadVC_File_ACCESS_DENIED_TIP", comment: "")
                    } else if error!.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED.rawValue {
                        if data.bTempNxlFile {
                            content = NSLocalizedString("FILE_OPERATION_MYVAULT_USED_UP_STORAGE_UPLOAD", comment: "")
                        } else {
                            content = NSLocalizedString("FILE_OPERATION_USED_UP_STORAGE_UPLOAD", comment: "")
                        }
                    } else {
                        content = NSLocalizedString("FILE_OPERATION_UPLOAD_FAILED", comment: "")
                    }
                } else {
                    if data.bTempNxlFile {
                        content = "The rights-protected file " + url.lastPathComponent + " has been upload my vault successfully"
                    }
                }
                
                NXCommonUtils.showNotification(title:"SkyDRM", content:content)
                
                if data.bTempNxlFile {
                    NXCommonUtils.removeTempFileAndFolder(tempPath: URL(fileURLWithPath: data.srcPath))
                }
                
                if error == nil {
                    // myvault change
                    if data.bTempNxlFile {
                        NotificationCenter.default.post(name: NSNotification.Name("myVaultDidChanged"),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                    
                    self.retrieveFilesFromNetwork(folder: self.curNode)
                    self.updateMySpaceStorageUI()
                }
                let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
                self.progressTreeViewController?.setStatus(id: id, status: status)
            }
            else if let data = data as? rangeDownloadData {
                let fileURL = URL(fileURLWithPath: data.cachePath)
                NXLoginUser.sharedInstance.nxlClient?.getNXLFileRights(fileURL, withCompletion: {(rights, isSteward, error) in
                    var content = ""
                    if let error = error as NSError? {
                        if error.code == 403 {
                            self.sendLogToRMS(accessResult: false, file: data.file, type: .Download, filePath: data.cachePath, needDelete: true)
                            content.append(NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_RIGHTS", comment: ""))
                            content.append(":\(data.file.name)")
                            NXCommonUtils.showNotification(title:"SkyDRM", content: content)
                        }
                        else {
                            content.append(NSLocalizedString("FILE_LOCAL_INFO_GET_RIGHTS_FAILED", comment: ""))
                            content.append(":\(data.file.name)")
                            NXCommonUtils.showNotification(title:"SkyDRM", content: content)
                            NXCommonUtils.removeTempFileAndFolder(tempPath: fileURL)
                        }
                    }
                    else {
                        if rights?.getRight(.NXLRIGHTSDOWNLOAD) == false, isSteward == false {
                            self.sendLogToRMS(accessResult: false, file: data.file, type: .Download, filePath: data.cachePath, needDelete: true)
                            content.append(NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_RIGHTS", comment: ""))
                            content.append(":\(data.file.name)")
                            NXCommonUtils.showNotification(title:"SkyDRM", content: content)
                        }
                        else {
                            self.downloadFiles.append(data.file)
                            NXCommonUtils.removeTempFileAndFolder(tempPath: fileURL)
                        }
                    }
                    if let id = self.checkedDownloadFiles.firstIndex(of: data.file) {
                        self.checkedDownloadFiles.remove(at: id)
                    }
                    if self.checkedDownloadFiles.isEmpty {
                        DispatchQueue.main.async {
                            self.fileTableWaitView.isHidden = true
                        }
                        self.beginDownload(files: self.downloadFiles, dstUrl: self.downloadURL)
                    }
                    
                })
            }
        }
    }
}

extension NXFileListView: NXProgressTreeViewControllerDelegate {
    func itemCancel(id: Int) {
        DownloadUploadMgr.shared.cancel(id: id)
    }
}


extension NXFileListView: NXRepositoryFileServiceOperationDelegate {
    func getFavFileFinish(repoId: String, favFile: NXRepoFavFileItem?, error: Error?, customData: Any?) {
        DispatchQueue.main.async {
            let item = NXFavOperationItem(repoId: repoId, service: nil)
            _ = self.serviceManger.remove(element: item)
            
            let servicePath = customData as? String
            
            if self.isNodeChange(with: servicePath) {
                Swift.print("node was changed, this data doesn't make sense, doesn't need to do anything")
                return
            }
            
            self.updateCoreData(servicePath: servicePath, favFile: (error == nil) ? favFile : nil)
            if self.currentSelectedItem == .allFiles {
                if self.serviceManger.isEmpty() {
                    self.fileOperationBar?.settingFileOperationBtnStatus(with: self.currentSelectedItem!)
                    self.refreshData()
                }
            } else {
                self.fileOperationBar?.settingFileOperationBtnStatus(with: self.currentSelectedItem!)
                self.refreshData()
            }
        }
        
    }
    
    func markAsFavFileFinish(files: [NXFileBase], error: Error?) {
        guard error == nil else {
            debugPrint("mark fav error: \(String(describing: error))")
            return
        }
        
        if CacheMgr.shared.updateFavOrOffline(isFav: true, files: files) {
            reloadFileList()
        }
    }
    
    func unmarkFavFileFinish(files: [NXFileBase], error: Error?) {
        guard error == nil else {
            debugPrint("unmark fav error: \(String(describing: error))")
            return
        }

        if CacheMgr.shared.updateFavOrOffline(isFav: true, files: files) {
            reloadFileList()
        }
    }
    
    func getAllFavFilesFinish(files: [NXRepoFavFileItem]?, error: Error?) {
        if error != nil {
            debugPrint("get all fav error: \(String(describing: error))")
            return
        }
        
        guard let repos = files else {
            debugPrint("get all fav fail")
            return
        }
        //////////////////////////////////////////////////////////////////////////////////
        // update core data
        
        // remove all favorite
        if repos.isEmpty {
            _ = CacheMgr.shared.syncSkyDrmFavorite(with: [])
            
        } else {
            let mydrives = repos.filter() { $0.repoType == "S3" }
            if let mydrive = mydrives.first,
                let markFiles = mydrive.markFiles {
                _ = CacheMgr.shared.syncSkyDrmFavorite(with: markFiles)
            }
        }
        
        //////////////////////////////////////////////////////////////////////////////////
        
        // update ui data from core data
        reloadFileList()
    }
}

extension NXFileListView: NXAuthMgrDelegate {
    func addFinished(repo: NXRMCRepoItem?, error: NSError?) {
        defer {
            stopAnimation()
        }
        if let _ = error {
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("REPOSITORY_ADD_FAILED", comment: ""))
            }
            return
        }
        guard
            let repo = repo,
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
            let bs = currentSelectedCloudDriveBoundService,
            let root = currentSelectedCloudDriveFolder
        else { return }
        
        let item = NXRMCRepoItem(from: bs)
        if item != repo {
            NSAlert.showAlert(withMessage: NSLocalizedString("HOME_REPOSITORY_REAUTH_FAILED", comment: ""))
            NXAuthMgr.shared.remove(item: repo)
            return
        }
        item.token = repo.token
        item.accountId = repo.accountId
        item.isAuth = true
        
        if (CacheMgr.shared.addAndUpdateBoundService(userId: userId, repository: item)) {
            NXLoginUser.sharedInstance.updateRepository(repository: repo)
        }
        
        let target: NXBoundService? = {
            if let bsInCache = DBBoundServiceHandler.shared.fetchBoundService(with: bs.repoId, type: ServiceType(rawValue: bs.serviceType)!) {
                let bs = NXBoundService()
                DBBoundServiceHandler.formatNXBoundService(src: bsInCache, target: bs)
                return bs
            }
            return nil
        }()
        
        guard let bsFromCache = target else {
            return
        }
        
        for (index, service) in allBoundServices.enumerated() {
            if service.boundService.serviceType == bsFromCache.serviceType,
                service.boundService.repoId == bsFromCache.repoId {
                allBoundServices[index].boundService = bsFromCache
                break
            }
        }
        
        navView.updateMenuItem(with: bsFromCache)
        DispatchQueue.main.async {
            self.showBoundService(service: (bsFromCache, root))
        }
    }
}

extension NXFileListView: NXSharedWithMeServiceDelegate {
    func listFileFinish(with filter: NXSharedWithMeListFilter?, files: [NXFileBase]?, error: Error?) {
        // Current UI is sharedWithMe
        guard currentSelectedItem == .shared, isSharedWithMe == true else {
            return
        }
        
        DispatchQueue.main.async {
            self.waitView.isHidden = true
            self.fileTableWaitView.isHidden = true
        }
        
        guard error == nil, let files = files else {
            debugPrint(error ?? "")
            return
        }
        
        if let service = allShownServices.first {
            _ = files.map() { $0.boundService = service.boundService }
            
            _ = CacheMgr.shared.saveMyVaultFiles(bs: service.boundService, files: files, isSharedWithMe: true)
            let sharedWithMeFiles = DBSharedWithMeFileHandler.shared.getAll()
            
            let array = NSMutableArray.init(array: sharedWithMeFiles)
            dataMyVaultTableView?.refreshView(files: array, showEmptyImage: true)
            dataMyVaultTableView?.updateData(searchString: fileOperationBar!.searchField.stringValue, showEmptyImage: true)
        }
        
    }
}
