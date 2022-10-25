//
//  NXSpecificProjectHomeRecentView.swift
//  skyDRM
//
//  Created by helpdesk on 2/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomeRecentView: NSView {
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet weak var emptyView: NSImageView!
    @IBOutlet weak var collectionScrollView: NSScrollView!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var addBtn: NSButton!
    @IBOutlet weak var viewAllFilesBtn: NSButton!
    @IBOutlet weak var waitView: NSProgressIndicator!
    struct Constant {
        static let collectionViewItemIdentifier = "NXSpecificProjectHomeRecentFileItem"
        
        static let itemHeight: CGFloat = 60
        static let standardInterval: CGFloat = 0
        
        static let maxDisplayCount = 4
    }
    
    weak var delegate: NXSpecificProjectHomeRecentDelegate?
    
    fileprivate var projectInfo = NXProject()
    fileprivate var projectService: NXProjectAdapter?
    fileprivate var curNode : NXFileBase? = nil
    
    fileprivate var curShownFiles = NSMutableArray()
    
    fileprivate var progressTreeViewController:NXProgressTreeViewController?
    private var infoConext = 0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    
    @IBAction func addFile(_ sender: Any) {
        addFile()
    }
    @IBAction func viewAll(_ sender: Any) {
        delegate?.viewAllFiles()
    }
    
    override func viewWillDraw() {
        collectionView?.collectionViewLayout?.invalidateLayout()
    }
    
    func addFile() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.beginSheetModal(for: NXSpecificProjectWindow.sharedInstance.window!) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let uploadVC = NXProjectUploadVC(nibName: "NXProjectUploadVC", bundle: nil)
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
                    NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_HOME_RENCENT_UPLOAD_FAILED", comment: ""), informativeText: "", dismissClosure: { (type) in
                    })
                    return
                }
                
                uploadVC.localPath = openPanel.url
                uploadVC.delegate = self
                NSApplication.shared.mainWindow?.contentViewController?.presentAsModalWindow(uploadVC)
            }
        }
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
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        self.projectInfo = NXSpecificProjectData.shared.getProjectInfo()
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }
        
        collectionView?.layer?.backgroundColor = WHITE_COLOR.cgColor
        configureCollectionView()
        addBtn.title = NSLocalizedString("PROJECT_RECENT_FILES_ADD_FILE_BUTTON", comment: "")
        addBtn.wantsLayer = true
        addBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        addBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: addBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, addBtn.title.count))
        addBtn.attributedTitle = titleAttr
        
        viewAllFilesBtn.stringValue = NSLocalizedString("PROJECT_RECENT_FILES_VIEW_BUTTON", comment: "")
        if let textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0) {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = .center
            let titleAttr = NSMutableAttributedString(attributedString: viewAllFilesBtn.attributedTitle)
            titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, viewAllFilesBtn.title.count))
            viewAllFilesBtn.attributedTitle = titleAttr
        }
        emptyLabel.stringValue = NSLocalizedString("PROJECT_RECENT_FILES_NO_RECENT_FILES", comment: "")
        emptyLabel.isHidden = true
        emptyView.isHidden = true
        
        self.wantsLayer = true
        self.layer?.backgroundColor = WHITE_COLOR.cgColor
        getData()
    }
    
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        debugPrint("First:\(self.bounds.width)")
        flowLayout.itemSize = NSSize(width: self.bounds.width, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        collectionView.collectionViewLayout = flowLayout
    }
    
    fileprivate func getData(){
        waitView.startAnimation(nil)
        waitView.isHidden = false
        let parentPath = "/"
        let filter = NXProjectFileFilter(page: "1", size: "\(Constant.maxDisplayCount)", orderBy: [NXProjectFileSortType.fileName(isAscend: true)], pathId: parentPath)
        projectService?.listFile(project: projectInfo, filter: filter)
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
}

extension NXSpecificProjectHomeRecentView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(curShownFiles.count, Constant.maxDisplayCount)
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem{
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        guard let collectionViewItem = viewItem as? NXSpecificProjectHomeRecentFileItem else{
            return viewItem
        }
        collectionViewItem.itemValue = curShownFiles[indexPath.item] as? NXProjectFile
        collectionViewItem.delegate = self
        
        return collectionViewItem
    }
}
extension NXSpecificProjectHomeRecentView:NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath)->NSSize{
        Swift.print("NXSpecificProjectHomeRecentView %f", self.bounds.width);
        return NSSize(width: self.bounds.width, height: Constant.itemHeight)
    }
}

extension NXSpecificProjectHomeRecentView: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    
    }
}

extension NXSpecificProjectHomeRecentView : NXProjectAdapterDelegate {
    func listFileFinish(projectId: String, filter: NXProjectFileFilter, fileList: [NXFileBase]?, error: Error?) {
        
        waitView.stopAnimation(self)
        waitView.isHidden = true
        let files = NSMutableArray()
        if fileList != nil && fileList?.count != 0 {
            var filterFileList = [NXProjectFile]()
            for item in fileList! {
                if ((item as? NXProjectFile) != nil) {
                    filterFileList.append(item as! NXProjectFile)
                }
            }
            
            filterFileList.sort(by: { item1, item2 in !(item1.creationTime!.isLess(than: item2.creationTime!)) })
            
            files.addObjects(from: filterFileList)
        }
        curShownFiles = NSMutableArray(array: files)
        if curShownFiles.count == 0 {
            emptyLabel.isHidden = false
            emptyView.isHidden = false
            collectionScrollView.isHidden = true
        }
        else {
            emptyView.isHidden = true
            emptyLabel.isHidden = true
            collectionScrollView.isHidden = false
            collectionView.reloadData()
        }
        
    }
    func uploadFileProgress(projectId: String, localPath: String, progress: Double) {
        progressTreeViewController?.updateProgress(id: 0, progress: progress)
    }
    
    func uploadFileFinish(projectId: String, from: String, to: String?, error: Error?) {
        let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
        progressTreeViewController?.setStatus(id: 0, status: status)
        
//        let url = URL(fileURLWithPath: from)
        if error == nil {
            projectInfo.totalFiles += 1
            NXSpecificProjectData.shared.setProjectInfo(info: projectInfo.copy() as! NXProject)
            let content = "The rights-protected file " + URL(fileURLWithPath: to!).lastPathComponent + " has been upload successfully"
            NXCommonUtils.showNotification(title:"SkyDRM", content:content)
        } else {
            debugPrint("upload file failed")
            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_UPLOAD_FAILED", comment: ""))
            return
        }
        
        self.getData()
    }
    
    func downloadFileProgress(projectId: String, servicePath: String, progress: Double) {
        progressTreeViewController?.updateProgress(id: 0, progress: progress)
    }
    
    func downloadFileFinish(projectId: String, from: String, to: String, file: NXProjectFile?, error: Error?, forViewer: Bool) {
        if error != nil {
            try? FileManager.default.removeItem(atPath: to)
        } else {
            file?.localPath = to
            NXFileRenderManager.shared.viewFile(item: file!, renderEventSrc: .project)
        }
        
        let status: RunningFile.RunningFileStatus = (error == nil) ? .finish : .fail
        progressTreeViewController?.setStatus(id: 0, status: status)
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
}

extension NXSpecificProjectHomeRecentView: NXSpecificProjectHomeRecentItemDelegate {
    func onClick(file: NXProjectFile?) {
        if NXFileRenderSupportUtil.renderFileType(fileName: (file?.name)!) == NXFileContentType.NOT_SUPPORT {
            NSAlert.showAlert(withMessage: NSLocalizedString("PROJECT_FILES_RENDER_FAILED", comment: ""))
            return
        }else if NXFileRenderSupportUtil.renderFileType(fileName: (file?.name)!) == NXFileContentType.REMOTEVIEW{
            NXFileRenderManager.shared.viewFile(item: file!, renderEventSrc: .project)
            return
        }
        
        if (projectService?.downlodFile(file: file!, start: 0, length: (file?.size), forViewer: true))! {
            var runningFiles = [RunningFile]()
            let runningFile = RunningFile(name: (file?.name)!, type: .download, id: 0)
            runningFiles.append(runningFile)
            
            progressTreeViewController = self.createProgressViewController(withFiles: runningFiles)
        }
    }
}

extension NXSpecificProjectHomeRecentView : NXProjectUploadVCDelegate {
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
        if let _ = projectService?.uploadFile(fromFile: projectFile, toFolder: parentFolder as! NXProjectFolder, property: property){
            // 2. create runningfiles
            var runningFiles = [RunningFile]()
            let runningFile = RunningFile(name: projectFile.name, type: .upload, id: 0)
            runningFiles.append(runningFile)
            
            // 3. create progress viewcontroller
            progressTreeViewController = self.createProgressViewController(withFiles: runningFiles)
        }
    }
}

extension NXSpecificProjectHomeRecentView : NXProgressTreeViewControllerDelegate {
    func itemCancel(id: Int) {
        projectService?.cancelDownloadOrUploadFile()
    }
}

