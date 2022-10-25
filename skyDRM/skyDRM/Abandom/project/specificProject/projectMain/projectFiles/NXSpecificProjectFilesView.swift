//
//  NXSpecificProjectFilesView.swift
//  skyDRM
//
//  Created by helpdesk on 2/23/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectFilesView: NSView {

    let kOperationBarHeight:CGFloat = 80
    let kDataTableViewMargin : CGFloat = 70
    
    fileprivate var waitView: NXWaitingView!
    //
    fileprivate var projectInfo = NXProject()
    
    fileprivate var progressTreeViewController:NXProgressTreeViewController?
    
    fileprivate var projectService: NXProjectAdapter?
    
    //
    fileprivate var dataTableView : NXProjectFileTableView? = nil
    var fileOperationBar : NXFileOperationBar? = nil
    
    //
    fileprivate var curNode : NXFileBase? = nil
    fileprivate var curShownFiles = NSMutableArray()
    
    var selectedFiles:[NXFileBase] = []
    
    var downloadBtnLock = false
    private var infoConext = 0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
        dataTableView?.removeFromSuperview()
        fileOperationBar?.removeFromSuperview()
        waitView.removeFromSuperview()
    }
    func focusSearchField() {
        guard let fileOperationBar = fileOperationBar else {
            return
        }
        fileOperationBar.focusSearchField()
    }
    func sortbyFilename(){
        dataTableView?.sortbyFileName()
    }
    
    func sortbyLastmodified() {
        dataTableView?.sortbyLastModified()
    }
    
    func sortbyFilesize() {
        dataTableView?.sortbyFileSize()
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = BK_COLOR.cgColor
        self.projectInfo = NXSpecificProjectData.shared.getProjectInfo().copy() as! NXProject
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        // create file view, including table and grid
        createFileView()
        createFileOperationBar()
        
        fileOperationBar?.showNode(node: nil)
        fileOperationBar?.enableCreateFolderButton(enable: true)
        
        waitView = NXCommonUtils.createWaitingView(superView: dataTableView!)
        waitView.isHidden = false
        
        showFilesUnderFolder(folder: nil)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            let gProjectInfo = NXSpecificProjectData.shared.getProjectInfo()
            self.projectInfo = gProjectInfo.copy() as! NXProject
            
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    private func createFileView(){
        if dataTableView == nil {
            let frame = NSRect(x: kDataTableViewMargin, y: 0, width: self.frame.width - kDataTableViewMargin * 2, height: self.frame.height - kOperationBarHeight)
            dataTableView = NXCommonUtils.createViewFromXib(xibName: "NXProjectFileTableView", identifier: "projectFileTableView", frame: frame, superView: self) as? NXProjectFileTableView
            dataTableView?.doWork()
            dataTableView?.dataViewDelegate = self;
        }
    }
    private func createFileOperationBar(){
        if fileOperationBar == nil {
            let barRect = NSRect(x: kDataTableViewMargin, y: self.frame.height - kOperationBarHeight, width: self.frame.width - kDataTableViewMargin*2, height: kOperationBarHeight)
            fileOperationBar = NXCommonUtils.createViewFromXib(xibName: "NXFileOperationBar", identifier: "fileOperationBar", frame: barRect, superView: self) as? NXFileOperationBar
            fileOperationBar?.isSupportPreviousView = false
            
            fileOperationBar?.enableUploadButton(enable: true)
            
            fileOperationBar?.barDelegate = self
            fileOperationBar?.doWork(viewMode: .tableView)
        }
    }
    
    public func refreshDataView(showEmptyImage: Bool = true) {
        dataTableView?.refreshView(files: curShownFiles, showEmptyImage: showEmptyImage)
        dataTableView?.updateData(searchString: fileOperationBar!.searchField.stringValue, showEmptyImage: showEmptyImage)
    }
    
    public func showFilesUnderFolder(folder:NXFileBase?){
        curNode = folder
        fileOperationBar?.showNode(node: curNode)
        
        if curNode == nil {
            self.retrieveFilesUnderFolder(folder: curNode)
            return
        }
        curShownFiles.removeAllObjects()
        selectedFiles.removeAll()
        refreshDataView(showEmptyImage: false)
        
        if (curNode?.getChildren() == nil ||
            curNode?.getChildren()?.count == 0){
            self.retrieveFilesUnderFolder(folder: curNode)
        } else {
            guard let files = curNode?.getChildren() else {
                dataTableView?.refreshView(files: curShownFiles)
                return
            }
            curShownFiles = NSMutableArray(array: files)
            dataTableView?.refreshView(files: curShownFiles)
        }
    }
    
    fileprivate func deleteFile(file:NXFileBase?){
        
        let question:String
        let title:String
        
        if ((file as? NXProjectFolder) != nil) {
            question = NSLocalizedString("DELETE_FOLDER_TIPS", comment: "")
            title = NSLocalizedString("TITLE_DELETE_FOLDER", comment: "")
        }
        else {
            question = NSLocalizedString("DELETE_FILE_TIPS", comment: "")
            title = NSLocalizedString("TITLE_DELETE_FILE", comment: "")
        }
        
        NSAlert.showAlert(withMessage: question, confirmButtonTitle: NSLocalizedString("Confirm", comment: ""), cancelButtonTitle: NSLocalizedString("Cancel", comment:""), defaultCancelButton: true, titleName: title) { (type) in
            if type == .sure {
                self.projectService?.delegate = self
                if (file?.isKind(of: NXProjectFolder.self))! {
                    let projectFolder = file as! NXProjectFolder
                    projectFolder.projectId = self.projectInfo.projectId
                    self.projectService?.deleteFile(file: projectFolder)
                } else {
                    let projectFile = file as! NXProjectFile
                    projectFile.projectId = self.projectInfo.projectId
                    self.projectService?.deleteFile(file: projectFile)
                }
            }
        }
    }
    
    fileprivate func downloadFiles(files: [NXFileBase]){
        if !self.downloadBtnLock{
            downloadBtnLock = true
            
            if files.count > 2 {
                return;
            }
            let projectFile = files.first as! NXProjectFile
            projectFile.projectId = projectInfo.projectId
            
            projectService?.delegate = self
            projectService?.getFileMetadata(file: projectFile)
        }
    }
    
    fileprivate func createProgressViewController(withFiles files: [RunningFile]) -> NXProgressTreeViewController? {
        // 1. progress view
        let progressViewController = NXProgressTreeViewController(nibName:  "NXProgressTreeViewController", bundle: nil)
        
       
        
        progressViewController.delegate = self
        
        // 2. set viewcontroller
        progressViewController.setDoing(doing: files)
        
        // 4. present progress view
        DispatchQueue.main.async {
            NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(progressViewController)
        }
        
        return progressViewController
    }
    
    fileprivate func uploadLocalFile(){
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.beginSheetModal(for: self.window!) { (result) in
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
                
                if (NXLoginUser.sharedInstance.nxlClient?.isNXLFile(openPanel.url))!{
                    NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_FILES_UPLOAD_FAILED", comment: ""), informativeText: "", dismissClosure: { (type) in
                    })
                    return
                }
                
                let uploadVC = NXProjectUploadVC()
                uploadVC.localPath = openPanel.url
                uploadVC.delegate = self
                NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(uploadVC)
        }
        }
    }
    
    fileprivate func createFolder(){
        let createFolderVC = NXCreateFolderPopViewController()
        createFolderVC.createFolderDelegate = self
        NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(createFolderVC)
    }
    
    func createSameFolderNameConflictTips(folderName:String) -> Bool
    {                        
        for item in curShownFiles {
            if (item as? NXProjectFolder)?.name.caseInsensitiveCompare(folderName) == .orderedSame {
                NSAlert.showAlert(withMessage: NSLocalizedString("PROJECt_FILES_EXIST_FILE", comment: ""));
                return false
            }
        }
        return true
    }
    
    
    //refresh
    fileprivate func retrieveFilesUnderFolder(folder node:NXFileBase?){
        var parentPath : String? = nil;
        if node == nil {
            parentPath = "/"
        } else {
            parentPath = (curNode as! NXProjectFolder).fullServicePath
        }
        let filter = NXProjectFileFilter(page: "1", size: "", orderBy: [NXProjectFileSortType.fileName(isAscend: true)], pathId: parentPath!)
        projectService?.listFile(project: projectInfo, filter: filter)
        
        fileOperationBar?.settingAllFileOperationBtnDisable()
        
        projectService?.delegate = self
        waitView.isHidden = false
    }
}

extension NXSpecificProjectFilesView : NXFileOperationBarDelegate {
    func fileOperationBarDelegate(type: NXFileOperationType, userData: Any?) {
        switch type {
        case .tableView:
            break
        case .gridView:
            break
        case .search:
            selectedFiles.removeAll()
            fileOperationBar?.enableDownloadButton(enable: false)
            NXMainMenuHelper.shared.onSpecificProjectTableDeselectFile()
            dataTableView?.updateData(searchString: userData as! String)
            break
        case .pathNodeClicked:
            let node = userData as? NXFileBase
            self.showFilesUnderFolder(folder: node)
            break
        case .refreshClicked:
            self.retrieveFilesUnderFolder(folder:curNode)
            break
        case .uploadFile:
            uploadLocalFile()
            break
        case .downloadFile:
            downloadFiles(files: selectedFiles)
            break
        case .createFolder:
            createFolder()
            break
        case .selectMenuItem:
            break
        default:
            break
        }
    }
}

extension NXSpecificProjectFilesView : NXCreateFolderPopViewDelegate {
    func createFolderPopViewFinished(type: NXCreateFolderEventType, newFolderName:String){
        if type == .cancelButtonClicked {
            return
        }
        
        if createSameFolderNameConflictTips(folderName:newFolderName) == false
        {
            return
        }
        
        let folder = NXProjectFolder()
        folder.name = newFolderName
        folder.projectId = projectInfo.projectId

        var parentFolder : NXProjectFolder
        
        if curNode == nil {
            parentFolder = NXProjectFolder()
            parentFolder.projectId = projectInfo.projectId
            parentFolder.fullServicePath = "/"
        } else {
            parentFolder = curNode as! NXProjectFolder
            parentFolder.projectId = projectInfo.projectId
        }
        
        
        projectService?.createFolder(folder: folder, parentFolder: parentFolder, autorename: false)
    }
}

extension NXSpecificProjectFilesView : NXDataViewDelegate {
    func folderClicked(folder:NXFileBase?) {
        Swift.print("folder clicked")
        fileOperationBar?.searchField.stringValue = ""
        self.showFilesUnderFolder(folder: folder);
        fileOperationBar?.enableDownloadButton(enable: false)
        NXMainMenuHelper.shared.onSpecificProjectTableDeselectFile()
    }
    
    func fileClicked(file:NXFileBase) {
        Swift.print("file clicked, index: \(String(describing: index))")
        guard let projectFile = file as? NXProjectFile else {
            Swift.print("incorrect file type")
            return
        }
        
        if NXFileRenderSupportUtil.renderFileType(fileName: (projectFile.name)) == NXFileContentType.NOT_SUPPORT {
            NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_FILES_RENDER_FAILED", comment: ""))
            return
        }else if NXFileRenderSupportUtil.renderFileType(fileName: projectFile.name) == NXFileContentType.REMOTEVIEW{
            NXFileRenderManager.shared.viewFile(item: projectFile, renderEventSrc: .project)
            return
        }
        
        if (projectService?.downlodFile(file: projectFile, start: 0, length: (projectFile.size), forViewer: true))! {
            var runningFiles = [RunningFile]()
            let runningFile = RunningFile(name: (projectFile.name), type: .download, id: 0)
            runningFiles.append(runningFile)
            
            progressTreeViewController = self.createProgressViewController(withFiles: runningFiles)
        }
    }
    
    func selectionChanged(files: [NXFileBase]) {
        Swift.print("selectionChanged: \(files)")
        
        selectedFiles = files
        
        if selectedFiles.count == 0 || selectedFiles.count > 2{
            fileOperationBar?.enableDownloadButton(enable: false)
            NXMainMenuHelper.shared.onSpecificProjectTableDeselectFile()
            return
        }
        
        var hasFolder = false
        for tmp in selectedFiles{
            if ((tmp as? NXProjectFolder) != nil){
                hasFolder = true
            }
        }
        
        if hasFolder {
            fileOperationBar?.enableDownloadButton(enable: false)
        }else{
            fileOperationBar?.enableDownloadButton(enable: true)
        }
        NXMainMenuHelper.shared.onSpecificProjectTableSelectFile(file: selectedFiles[0], ownedByMe: projectInfo.ownedByMe)
    }
    
    func fileOperation(type: NXFileOperation, file: NXFileBase?) {
        guard let file = file else {
            debugPrint("no file")
            return
        }
        switch type {
        case .openFile:
            if file is NXProjectFolder {
                folderClicked(folder: file)
            }
            else {
                fileClicked(file: file)
            }
        case .deleteFile:
            deleteFile(file: file)
            break;
        case .downloadFile:
            downloadFiles(files: [file])
            break;
        case .viewProperty:
            viewProperty(file: file)
            break;
        case .logProperty:
            
            if let file = file as? NXProjectFile {
                let activityLogVC = NXActivityLogViewController()
                activityLogVC.file = file
                
                NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(activityLogVC)
            }
            
            break;
        default:
            break;
        }
    }
    
    struct Constant {
        static let fileInfoViewControllerXibName = "FileInfoViewController"
    }
    
    func viewProperty(file: NXFileBase?) {
        let fileInfoViewController = FileInfoViewController(nibName:  Constant.fileInfoViewControllerXibName, bundle: nil)
      
        
        if let file = file as? NXProjectFile {
            file.projectId = projectInfo.projectId
        }
        NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(fileInfoViewController)
    }
}

extension NXSpecificProjectFilesView : NXProjectAdapterDelegate {
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXFileBase]?, error: Error?) {
        
        fileOperationBar?.defaultFileOperationStatusInProject()
        
        waitView.isHidden = true
        let files = NSMutableArray()
        if fileList != nil && fileList?.count != 0 {
            files.addObjects(from: fileList!)
        }
        if curNode == nil && filter.pathId == "/" {
            curShownFiles = NSMutableArray(array: files)
            
            refreshDataView()
            return
        }
        if (curNode as! NXProjectFolder).fullServicePath == filter.pathId {
            curShownFiles = NSMutableArray(array: files)
            for file in curShownFiles {
                curNode?.addChild(child: file as! NXFileBase)
            }
            refreshDataView()
            return
        }
        Swift.print("not same directory")
    }
    
    func createFolderFinish(projectId: String, servicePath: String, error: Error?) {
        if error == nil {
            self.retrieveFilesUnderFolder(folder: curNode)
            
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_SUCCESS", comment: ""))
            }
            
            return
        }
        
        DispatchQueue.main.async {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATE_FOLDER_FAILED", comment: ""))
        }
    }
    
    func deleteFileFinish(projectId: String, servicePath: String, isFolder: Bool, error: Error?) {
        
        if error != nil {
            DispatchQueue.main.async {
                NXToastWindow.sharedInstance?.toast(String(format: NSLocalizedString("MY_SPACE_DELETE_FAILED", comment: ""), URL(fileURLWithPath: servicePath).lastPathComponent))
            }
            return
        }
        
        for file in curShownFiles {
            if let file = file as? NXFileBase,
                file.fullServicePath == servicePath {
                curShownFiles.remove(file)
                if !isFolder {
                    projectInfo.totalFiles -= 1
                    NXSpecificProjectData.shared.setProjectInfo(info: projectInfo.copy() as! NXProject)
                }
                
                break
            }
        }
        
        DispatchQueue.main.async {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("MY_SPACE_DELETE_SUCCESS", comment: ""))
            self.refreshDataView()
        }
                
    }
    
    func downloadFileFinish(projectId: String, from: String, to: String, file: NXProjectFile?, error: Error?, forViewer: Bool) {
        waitView.isHidden = true
        
        if error != nil {
            try? FileManager.default.removeItem(atPath: to)
        }
        
        if error == nil {
            // post notification about myVault change
            if !forViewer {
                NotificationCenter.default.post(name: NSNotification.Name("myVaultDidChanged"),
                                                object: nil,
                                                userInfo: nil)
            } else {
                file?.localPath = to
                NXFileRenderManager.shared.viewFile(item: file!, renderEventSrc: .project)
            }
        }
        
        let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
        progressTreeViewController?.setStatus(id: 0, status: status)
        
        if !forViewer {
            let url = URL(fileURLWithPath: to)
            
            if status == .finish {
                let content = "Download file: " + url.lastPathComponent + " successfully"
                NXCommonUtils.showNotification(title:"SkyDRM", content:content)
            }
        }
        
        if status != .finish,
           let backendError = error as? BackendError{
            switch backendError {
            case .failResponse(let reason):
                if reason == "error code: 404" {
                    NXCommonUtils.showNotification(title:"SkyDRM", content:NSLocalizedString("FILE_RENDER_PROJECT_FILE_NOT_EXIST", comment: ""))
                }
                return
            default:
                NXCommonUtils.showNotification(title:"SkyDRM", content:NSLocalizedString("FILE_RENDER_DOWNLOAD_FAILED", comment: ""))
                return
            }
        }
    }
    
    func downloadFileSuggestedFileName(projectId: String, servicePath: String, fileName: String, forViewer: Bool) {
        if !forViewer {
            waitView.isHidden = true
            
            var runningFiles = [RunningFile]()
            let runningFile = RunningFile(name: fileName, type: .download, id: 0)
            runningFiles.append(runningFile)
            
            self.progressTreeViewController = self.createProgressViewController(withFiles: runningFiles)
        }
    }
    
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double) {
        progressTreeViewController?.updateProgress(id: 0, progress: progress)
    }
    
    func uploadFileProgress(projectId: String, localPath: String, progress: Double) {
        progressTreeViewController?.updateProgress(id: 0, progress: progress)
    }
    
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?) {
        let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
        
        progressTreeViewController?.setStatus(id: 0, status: status)
        
        if status == .finish {
            projectInfo.totalFiles += 1
            NXSpecificProjectData.shared.setProjectInfo(info: projectInfo.copy() as! NXProject)
            
            let content = "The rights-protected file " + URL(fileURLWithPath: to!).lastPathComponent + " has been upload successfully"
            NXCommonUtils.showNotification(title:"SkyDRM", content:content)
        } else {
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_UPLOAD_FAILED", comment: ""))
            return
        }
    
        self.retrieveFilesUnderFolder(folder: curNode)
    }
    
    func getFileMetadataFinish(projectId: String, servicePath: String, file: NXProjectFile?, error: Error?) {
        self.downloadBtnLock = false
        if let _ = error {
            NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_FILES_RETRIEVE_FILES_FAILED", comment: ""));
            return
        }
        guard let file = file else {
            Swift.debugPrint("get metadata with empty filebase")
            return
        }

        var canDownload = false
        
        if file.owner?.userId == NXLoginUser.sharedInstance.nxlClient?.userID {
            canDownload = true
        } else {
            for right in file.rights! {
                if right == .saveAs {
                    canDownload = true
                    break
                }
            }
        }
        
        if canDownload == false {
            sendLogToRMS(file: file)
            NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_FILES_NO_DOWNLOAD_RIGHTS", comment: ""), informativeText: "", dismissClosure: { (type) in
            })
            return
        }
        
        let savePanel = NSOpenPanel()
        savePanel.canChooseFiles = false
        savePanel.canChooseDirectories = true
        savePanel.beginSheetModal(for: self.window!) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let dest = savePanel.url
                
                if let _ = self.projectService?.downlodFile(file: file, toFolder: (dest?.path)! + "/", forViewer: false) {
                    self.projectService?.delegate = self
                    self.waitView.isHidden = false
                }
            }
        }
    }
    
    func sendLogToRMS(file: NXProjectFile?){
        guard
            let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId),
            let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)
            else { return }
        
        let logService = NXLogService(userID: userId, ticket: ticket)
        
        let putModel = NXPutActivityLogInfoRequestModel()
        
        let time:TimeInterval = NSDate().timeIntervalSince1970 ;
        let accessTime = Int(time*1000)
        let duid = file?.getNXLID() ?? ""
        
        putModel.duid = duid
        putModel.owner = ""
        putModel.operation = OperationEnum.Download.rawValue
        putModel.repositoryId = file?.boundService?.repoId ?? " "
        putModel.filePathId = " "
        putModel.fileName = file?.name
        putModel.filePath = file?.fullServicePath
        putModel.activityData = " "
        putModel.accessTime = accessTime
        putModel.userID = userId
        putModel.accessResult = 0
        
        logService.putActivityLogInfoWith(activityLogInfoRequestModel: putModel)
    }
}

extension NXSpecificProjectFilesView : NXProjectUploadVCDelegate {
    func uploadAction(forLocalPath localPath:URL?, rights:NXLRights?) {
        guard localPath != nil else {
            return
        }
        
        let propertyRights = NSMutableArray()
        
        
        let tagsDic = [String: Any]();
        
        if (rights?.getRight(.NXLRIGHTVIEW))! {
            propertyRights.add(NXProjectFileRightType.view)
        }
        
        if (rights?.getRight(.NXLRIGHTPRINT))! {
            propertyRights.add(NXProjectFileRightType.print)
        }
        
        if (rights?.getRight(.NXLRIGHTSDOWNLOAD))! {
            propertyRights.add(NXProjectFileRightType.download)
        }
        
        if (rights?.getObligation(.NXLOBLIGATIONWATERMARK))! {
            propertyRights.add(NXProjectFileRightType.overlay)
        }
        
        let property = NXProjectUploadFileProperty(rights: propertyRights as NSArray as! [NXProjectFileRightType], tags: tagsDic)
        
        let projectFile = NXProjectFile()
        
        projectFile.name = (localPath?.lastPathComponent)!
        projectFile.localPath = (localPath?.path)!
        projectFile.projectId = projectInfo.projectId
        
        var parentFolder = curNode
        
        if parentFolder == nil {
            parentFolder = NXProjectFolder()
            (parentFolder as! NXProjectFolder).fullServicePath = "/"
        }
        (parentFolder as! NXProjectFolder).projectId = projectInfo.projectId
        
        //1. upload
        if let _ = projectService?.uploadFile(fromFile: projectFile, toFolder: parentFolder as! NXProjectFolder, property: property) {
            self.projectService?.delegate = self
            
            // 2. create runningfiles
            var runningFiles = [RunningFile]()
            let runningFile = RunningFile(name: projectFile.name, type: .upload, id: 0)
            runningFiles.append(runningFile)
            
            // 3. create progress viewcontroller
            progressTreeViewController = self.createProgressViewController(withFiles: runningFiles)
        }
    }
}

extension NXSpecificProjectFilesView : NXProgressTreeViewControllerDelegate {
    func itemCancel(id: Int) {
        self.projectService?.cancelDownloadOrUploadFile()
    }
}
