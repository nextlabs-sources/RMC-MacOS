//
//  NXMyVaultViewController.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2018/12/18.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXMyVaultViewControllerDelegate: class {
    func addFileToProject(nxlFile: NXProjectFileModel)
}

class NXMyVaultViewController: NSViewController {
    
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var listEmptyView: NSView!
    @IBOutlet weak var name: NSTableColumn!
    @IBOutlet weak var fileLocation: NSTableColumn!
    @IBOutlet weak var dateModified: NSTableColumn!
    @IBOutlet weak var shareWith: NSTableColumn!
    @IBOutlet weak var size: NSTableColumn!
    @IBOutlet weak var emptyFolderLab: NSTextField!
    
    var orderType: NXListType = .myVault
    var projectType: NXListType = .projectFile
    // All file data.
    var data = [NXSyncFile]()
    
    // Display file data.
    @objc dynamic var displayData = [NXSyncFile]()
    @objc dynamic var displayCount: Int {
        get {
            return displayData.count
        }
    }
    
    // Configure
    var sortOrder = NXListOrder.dateModified
    var sortAscending = false
    var searchString = ""
    weak var delegate: NXMyVaultViewControllerDelegate?
    
    var selectedFile: NXSyncFile? {
        let row = fileTableView.selectedRow
        if row == -1 {
            return nil
        }
        return displayData[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // FIXME: Not good using system to store.
        //        fileTableView.autosaveName = NXClientUser.shared.user!.name
        //        fileTableView.autosaveTableColumns = true
        
        fileTableView.allowsColumnReordering = true
        listEmptyView.isHidden = true
        initView()
        locationed()
        addObserver()
        
        initData(refresh: false)
      
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    deinit {
        removeObserver()
    }
    // MARK:ChangeLanuages
    fileprivate func locationed() {
        emptyFolderLab.stringValue = "FILE_INFO_EMPTY_FOLDER".localized
        name.title = "FILE_INFO_FILENAME".localized
        fileLocation.title = "FILE_INFO_FILELOCATION".localized
        dateModified.title = "FILE_INFO_MODIFIEDTIME".localized
        shareWith.title = "FILE_INFO_SHAREDWITH".localized
        size.title = "FILE_INFO_SIZE".localized
    }
    // MARK: System action.
    override func rightMouseDown(with event: NSEvent) {
        let mousePoint = view.convert(event.locationInWindow, from: nil)
        let mouseInTable = view.convert(mousePoint, to: self.fileTableView)
        let mouseRow = fileTableView.row(at: mouseInTable)
        if mouseRow == -1 {
            return
        }
        selectRow(row: mouseRow)
        
        let listItemContextMenu = NXLocalListItemContextMenu(title: "")
        listItemContextMenu.operationDelegate = self
        listItemContextMenu.file = displayData[mouseRow]
        listItemContextMenu.popUp(positioning: listItemContextMenu.item(at: 0), at: mousePoint, in: self.view)
    }
    
    fileprivate func selectRow(row: Int) {
        let selectedRow = self.fileTableView.selectedRow
        if selectedRow == row {
            return
        } else {
            self.fileTableView.deselectRow(selectedRow)
            let rows = IndexSet.init(integer: row)
            self.fileTableView.selectRowIndexes(rows, byExtendingSelection: true)
        }
    }
}
// MARK: Sort.

extension NXMyVaultViewController {
    fileprivate func filterCompletion() {
            displayData = data
        }
    fileprivate func filterWithSearchString() {
        if searchString.isEmpty {
            displayData = data
        } else {
            let filterData = data.filter() {$0.file.name.localizedCaseInsensitiveContains(searchString)}
            displayData = filterData
        }
    }
    
     func getOrderFiles(files: [NXSyncFile], sortOrder: NXListOrder, ascending: Bool) -> [NXSyncFile] {
        let sortedFiles: [NXSyncFile]
        switch sortOrder {
        case .name:
            sortedFiles = files.sorted {
                return ascending ?($0.file.name.compare($1.file.name, options: .caseInsensitive) == .orderedAscending):($0.file.name.compare($1.file.name, options: .caseInsensitive) == .orderedDescending)
            }
          
        case .dateModified:
            if self.orderType == .sharedWithMe{
                sortedFiles = files.sorted {
                    let shareWithMeFile0 = $0.file.sdmlBaseFile as? SDMLShareWithMeFile
                    let shareWithMeFile1 = $1.file.sdmlBaseFile as? SDMLShareWithMeFile
                    if shareWithMeFile0!.getSharedDate() == shareWithMeFile1!.getSharedDate() { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase}
                    return itemComparator(lhs: shareWithMeFile0!.getSharedDate(), rhs: shareWithMeFile1!.getSharedDate(), ascending: ascending)
                }
            }else{
                sortedFiles = files.sorted {
                    if $0.file.lastModifiedDate == $1.file.lastModifiedDate { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase}
                    return itemComparator(lhs: $0.file.lastModifiedDate as Date, rhs: $1.file.lastModifiedDate as Date, ascending: ascending)
                }
            }
        case .size:
            sortedFiles = files.sorted {
                if $0.file.size == $1.file.size { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase }
                return itemComparator(lhs: $0.file.size, rhs: $1.file.size, ascending: ascending)
            }
        case .fileLocation:
            sortedFiles = files.sorted {
                if $0.file.localFile == $1.file.localFile { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase }
                return itemComparator(lhs: $0.file.localFile == true ?1:0, rhs: $1.file.localFile == true ?1:0, ascending: ascending)
            }
        case .sharedWith:
            
            if self.orderType == .allOffline{
                sortedFiles = files.sorted {

                    var typeStrLhs = ""
                    var typeStrRhs = ""
                    if  $0.file is NXShareWithMeFile {
                        typeStrLhs = "SIDERBAR_NAME_SHAREDWITHME".localized
                    }else if  $0.file is NXMyVaultFile {
                        typeStrLhs = "SIDERBAR_NAME_MYVAULT".localized
                    }else if  $0.file is NXProjectFileModel {
                        typeStrLhs = "SIDERBAR_NAME_PROJECT".localized
                    }
                    
                    if  $1.file is NXShareWithMeFile {
                        typeStrRhs = "SIDERBAR_NAME_SHAREDWITHME".localized
                    }else if  $1.file is NXMyVaultFile {
                        typeStrRhs = "SIDERBAR_NAME_MYVAULT".localized
                    }else if  $1.file is NXProjectFileModel {
                        typeStrRhs = "SIDERBAR_NAME_PROJECT".localized
                    }
                    
                    if typeStrLhs == typeStrRhs  { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase }
                    return itemComparator(lhs: "\(typeStrLhs)", rhs: "\(typeStrRhs)", ascending: ascending)
                }
            }else{
                if let file = files.first?.file as? NXShareWithMeFile
                {
                    YMLog("\(file.shareBy ?? "")")
                    sortedFiles = files.sorted {
                        let sharedWithMeFilelhs = $0.file as? NXShareWithMeFile
                        let sharedWithMeFilerhs = $1.file as? NXShareWithMeFile
                        
                        if sharedWithMeFilelhs?.shareBy == sharedWithMeFilerhs?.shareBy { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase }
                        return itemComparator(lhs: "\(sharedWithMeFilelhs?.shareBy! ?? "")", rhs: "\(sharedWithMeFilerhs?.shareBy! ?? "")", ascending: ascending)
                    }
                }else{
                    sortedFiles = files.sorted {
                        return ($0.file.name.compare($1.file.name, options: .caseInsensitive) == .orderedAscending)
                    }
                }
            }
        }
        return sortedFiles
    }
    
    fileprivate func sortContentOrderBy(_ sortOrder: NXListOrder, ascending: Bool) {
        self.displayData = getOrderFiles(files: self.displayData, sortOrder: sortOrder, ascending: ascending)
    }
    
    fileprivate func itemComparator<T: Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
        return ascending ? (lhs < rhs) : (lhs > rhs)
    }
    
    fileprivate func initSortDescriptor() {
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: self.sortOrder == .name ?(!self.sortAscending):true)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dateModified")) {
            let sortDescriptor = NSSortDescriptor.init(key: "dateModified", ascending: self.sortOrder == .dateModified ?(!self.sortAscending):false)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "size")) {
            let sortDescriptor = NSSortDescriptor.init(key: "size", ascending: self.sortOrder == .size ?(!self.sortAscending):true)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
    
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileLocation")) {
            let sortDescriptor = NSSortDescriptor.init(key: "fileLocation", ascending: self.sortOrder == .fileLocation ?(!self.sortAscending):true)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sharedWith")) {
            let sortDescriptor = NSSortDescriptor.init(key: "sharedWith", ascending: self.sortOrder == .sharedWith ?(!self.sortAscending):true)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
    }
    
    func sortTableviewOrderByName() {
        filterWithSearchString()
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.name, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }else{
                let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: true)
                sortContentOrderBy(NXListOrder.name, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
        }
        self.fileTableView.reloadData()
    }
    
    func sortTableviewOrderByDateLastmodified()
    {
        filterWithSearchString()
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dateModified")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.dateModified, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "dateModified", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }else{
                let sortDescriptor = NSSortDescriptor.init(key: "dateModified", ascending: true)
                sortContentOrderBy(NXListOrder.dateModified, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
        }
        self.fileTableView.reloadData()
    }
    
    func sortTableviewOrderBySize()
    {
        filterWithSearchString()
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "size")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.size, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "size", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }else{
                let sortDescriptor = NSSortDescriptor.init(key: "size", ascending: true)
                sortContentOrderBy(NXListOrder.size, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
        }
        self.fileTableView.reloadData()
    }
    
    func sortTableviewOrderByFileLocation(){
        filterWithSearchString()
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileLocation")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.size, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "fileLocation", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }else{
                let sortDescriptor = NSSortDescriptor.init(key: "fileLocation", ascending: true)
                sortContentOrderBy(NXListOrder.size, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
        }
        self.fileTableView.reloadData()
    }
}

extension NXMyVaultViewController {
    //fileprivate
    @objc func initData(refresh: Bool) {
        let files = NXMemoryDrive.sharedInstance.getMyVault()
        self.data = files
        
        reloadData(isRefresh: refresh)
    }
    
    func reloadData(isRefresh: Bool) {
        if isRefresh {
            self.sortOrder = .dateModified
            self.sortAscending = false
            self.displayData = self.getOrderFiles(files: self.data, sortOrder: self.sortOrder, ascending: self.sortAscending)
        } else {
            self.displayData = self.getOrderFiles(files: self.data, sortOrder: self.sortOrder, ascending: self.sortAscending)
        }
        
        // Update UI.
        self.displayEmptyView(isShow: self.data.isEmpty)
        self.fileTableView.reloadData()
    }
    
    fileprivate func initView() {
        initTableView()
        initSortDescriptor()
    }
    
    fileprivate func initTableView() {
        fileTableView.dataSource = self
        fileTableView.delegate = self
        fileTableView.target = self
        fileTableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    
    @objc fileprivate func tableViewDoubleClick(_ sender: Any) {
        openSelectedFile()
    }
    
     func displayEmptyView(isShow: Bool) {
        if isShow {
            listEmptyView.isHidden = false
        } else {
            listEmptyView.isHidden = true
        }
    }
}

// MARK: Notification.

extension NXMyVaultViewController {
  @objc  func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .myVaultProtected)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadMyvalut)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .startUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .stopUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploaded)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadFailed)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .removeFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .updateMyVaultFile)
    
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .refreshMyVault)
    }
    
    fileprivate func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .myVaultProtected {
            DispatchQueue.main.async {
                self.initData(refresh: false)
            }
        } else if notification.nxNotification == .uploadMyvalut ||
            notification.nxNotification == .startUpload ||
            notification.nxNotification == .stopUpload {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    self.displayStatusChange(file: file)
                }
            }
        } else if notification.nxNotification == .uploaded {
            if let syncFile = notification.object as? NXSyncFile,
                let _ = syncFile.file as? NXMyVaultFile {
                
                initData(refresh: false)
                
            }
            
        } else if notification.nxNotification == .uploadFailed {
            if let file = notification.object as? NXSyncFile,
                let error = notification.userInfo?["error"] as? Error {
                guard file.file is NXLocalProjectFileModel else {
                    DispatchQueue.main.async {
                        self.displayStatusChange(file: file)
                        self.displayUploadError(error: error)
                    }
                    return
                }
            }
        } else if notification.nxNotification == .removeFile {
            if let file = notification.object as? NXSyncFile,
                !(file.file is NXLocalProjectFileModel) {
                DispatchQueue.main.async {
                    self.initData(refresh: false)
                }
            }
            
        } else if notification.nxNotification == .updateMyVaultFile {
            if let file = notification.object as? NXSyncFile{
                DispatchQueue.main.async {
                    if let currentFile = self.getCurrentFile(file: file) {
                        self.updateMyVaultFile(file: currentFile, newFile: file)
                    }
                }
            }
        } else if notification.nxNotification == .refreshMyVault {
            DispatchQueue.main.async {
                self.initData(refresh: true)
            }
        }
    }
    
    func getCurrentFile(file: NXSyncFile) -> NXSyncFile? {
        for (index, item) in self.data.enumerated() {
            if let nxFile = item.file.sdmlBaseFile as? SDMLNXLFile, let removeFile = file.file.sdmlBaseFile as? SDMLNXLFile {
                if nxFile.getDUID() == removeFile.getDUID() {
                    return self.data[index]
                }
            }
        }
        return nil
    }
    
    fileprivate func displayUploadError(error: Error) {
        if let sdmlError = error as? SDMLError,
            case SDMLError.uploadFailed(reason: .storageExceeded) = sdmlError {
            NXToastWindow.sharedInstance?.toast("Storage exceeded")
        }
    }
    
    fileprivate func displayStatusChange(file: NXSyncFile) {
        let dataArr = displayData
        for (index, displayFile) in dataArr.enumerated() {
            if let nxFile = displayFile.file.sdmlBaseFile as? SDMLNXLFile, let removeFile = file.file.sdmlBaseFile as? SDMLNXLFile {
                if nxFile.getDUID() == removeFile.getDUID() {
                    displayData[index] = file
                    self.fileTableView.reloadData()
                    break
                }
            }
        }
    }
}

// File Operations.

extension NXMyVaultViewController {
    
    func viewFile(file: NXSyncFile) {
            NXFileRenderManager.shared.viewCache(file: file.file)
      
    }
    func removeFileManual(file: NXSyncFile, isNotifi: Bool) {
        if isNotifi {
            self.removeFileWithFile(file: file, isUpload: true)
            NotificationCenter.post(notification: .removeFile, object: file)
            return
        }
        NSAlert.showAlert(withMessage: "CONFIRM_DELETING_FILE".localized, confirmButtonTitle: "Remove", cancelButtonTitle: "Cancel") { (type) in
            if type == .sure {
                self.removeFileWithFile(file: file, isUpload: false)
                NotificationCenter.post(notification: .removeFile, object: file)
            }
        }
    }
    
    func removeFileWithFile(file: NXSyncFile,isUpload: Bool) {
        
        for (index, item) in self.data.enumerated() {
            if item == file {
                self.data.remove(at: index)
                self.displayEmptyView(isShow: self.data.isEmpty)
                break
            }
        }

        for (index, item) in self.displayData.enumerated() {
            if item == file {
                self.displayData.remove(at: index)
                break
            }
        }
        _ = NXClient.getCurrentClient().deleteFile(file: file.file, isUpload: isUpload)
        self.fileTableView.reloadData()
    }
    
 @objc  func removeFileAutomatic(file: NXSyncFile) {
        for (index, item) in self.data.enumerated() {
            if item == file {
                self.data.remove(at: index)
                self.displayEmptyView(isShow: self.data.isEmpty)
                break
            }
        }

        for (index, item) in self.displayData.enumerated() {
            if item == file {
                self.displayData.remove(at: index)
                break
            }
        }
    
    self.fileTableView.reloadData()
    let status = NXClientUser.shared.isOnline
    if status == false  {
        self.initData(refresh: false)
    } else {
        
        self.initData(refresh: true)
        
        }
    }
    
    func updateMyVaultFile(file: NXSyncFile, newFile: NXSyncFile) {
        for (index, item) in self.data.enumerated() {
            if item == file {
                self.data[index] = newFile
                break
            }
        }
        
        for (index, item) in self.displayData.enumerated() {
            if item == file {
                self.displayData[index] = newFile
                break
            }
        }
        self.fileTableView.reloadData()
    }
    
    func viewFileInfo(file: NXSyncFile) {
        let fileInfoViewController = FileInfoViewController(nibName:  "FileInfoViewController", bundle: nil)
        fileInfoViewController.file = file.file as? NXNXLFile
        self.presentAsModalWindow(fileInfoViewController)
    }
    
    func shareRecipients(file: NXSyncFile) {
        guard let nxlFile = file.file as? NXNXLFile else {
            return
        }
        
        let vc = NXHomeShareVC()
        vc.delegate = self
        vc.mainViewType = .configure
        vc.shareConfigFile = nxlFile
        self.presentAsModalWindow(vc)
    }
  @objc  func makeOffline(file:NXSyncFile) {
        let cellSelectedrow = fileTableView.selectedRow
        let cellCol = fileTableView.column(withIdentifier: NSUserInterfaceItemIdentifier.init("name"))
        let cellView = fileTableView.view(atColumn:cellCol,row: cellSelectedrow, makeIfNecessary: true)
        for view in (cellView?.subviews)! {
            if let progressBar = view as? NSProgressIndicator {
                progressBar.startAnimation(self)
                progressBar.isHidden = false
            }
        }
    
        file.file.fileStatus.insert(.downloading)
        NXClient.getCurrentClient().makeFileOffline(file: file) { [weak self] (file, error) in
            file?.file.fileStatus.remove(.downloading)
            if error == nil {
                self?.fileTableView.reloadData()
                NotificationCenter.post(notification: .download, object: file, userInfo: nil)
                NotificationCenter.post(notification: .allOfflineAddFile, object: file)
            } else {
                let message = "FILE_OPERATION_DOWNLOAD_FAILED".localized
                NSAlert.showAlert(withMessage: message)
                file?.syncStatus?.status = .pending
                self?.fileTableView.reloadData()
                NotificationCenter.post(notification: .download, object: file, userInfo: ["error":error!])
            }
        }
        self.fileTableView.reloadData()
        NotificationCenter.post(notification: .download, object: file, userInfo: nil)
    }

   @objc func makeUnOffline(file:NXSyncFile) {

        NXClient.getCurrentClient().makeFileOnline(file: file) {[weak self] (file, error) in
            if error == nil {
                NotificationCenter.post(notification: .unOfflineAndRemoveFile, object: file)
                self?.fileTableView.reloadData()
            }else {
                print(error as Any)
            }
        }
}
    
    func stopUploadAll() {
        NXSyncManager.shared.stopUploadAll()
    }
}

// MARK: - Public methods.

extension NXMyVaultViewController {
    
    func getItemCount() -> Int {
        return displayCount
    }
    
    func filter(with searchString: String) {
        self.searchString = searchString
        filterWithSearchString()
        self.fileTableView.reloadData()
    }
    func filterCompletioned() {
        filterCompletion()
        self.fileTableView.reloadData()
    }
    func openSelectedFile() {
        debugPrint(fileTableView.clickedRow)
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        if file.file.fileStatus.contains(.downloading) || file.file.fileStatus.contains(.uploading) {
            return
        }
        
        viewFile(file: file)
    }
    
    func removeSelectedFile() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        removeFileManual(file: file, isNotifi: false)
    }
    
    func viewSelectedFileInfo() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        
        viewFileInfo(file: file)
    }
    
    func shareSelectedFile() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        let file = displayData[self.fileTableView.selectedRow]
        shareRecipients(file: file)
    }
    
    func refresh() {
        self.fileTableView.reloadData()
    }
}

extension NXMyVaultViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        
        if let key = sortDescriptor.key,
            let order = NXListOrder(rawValue: key) {
            self.sortOrder = order
            self.sortAscending = sortDescriptor.ascending
            
        }
        
        sortContentOrderBy(self.sortOrder, ascending: self.sortAscending)
        self.fileTableView.reloadData()
    }
}

extension NXMyVaultViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self)
            else { return nil }
        // Setting subview content.
        if identifier.rawValue == "name" {
            if let iconImage = cellView.viewWithTag(0) as? NSImageView {
                let file = displayData[row]
                if file.syncStatus?.type  == .download {
                    for view in cellView.subviews {
                        if let progressBar = view as? NSProgressIndicator {
                            progressBar.isHidden = true
                            progressBar.stopAnimation(self)
                        }
                    }
                }
                var image: NSImage?
                iconImage.imageAlignment = .alignCenter
                let fileExtension = NXCommonUtils.getOriginFileExtension(filename: file.file.name)
                if let type = file.syncStatus?.type, let status = file.syncStatus?.status {
                    switch type {
                        case .upload:
                            for view in cellView.subviews {
                                if let progressBar = view as? NSProgressIndicator {
                                    progressBar.stopAnimation(self)
                                    progressBar.isHidden = true
                                }
                            }
                            switch status {
                            case .waiting:
                                let name = "\(fileExtension)_w"
                                image = NSImage.init(named: name)
                                if image == nil {
                                    image = NSImage(named: "- - -_w")
                                    }
                            case .pending:
                                let name = "\(fileExtension)_w"
                                image = NSImage.init(named:  name)
                                if image == nil {
                                    image = NSImage(named:  "- - -_w")
                                }
                            case .syncing:
                                let name = "\(fileExtension)_u"
                                image = NSImage.init(named: name)
                                if image == nil {
                                    image = NSImage(named: "- - -_u")
                                }

                            case .completed:
                                let name = "\(fileExtension)_d"
                                image = NSImage.init(named: name)
                                if image == nil {
                                    image = NSImage(named:"- - -_d")
                                }
                            for view in cellView.subviews {
                              if let progressBar = view as? NSProgressIndicator {
                                            progressBar.stopAnimation(self)
                                            progressBar.isHidden = true
                                        }
                                    }
                            case .failed:
                                let name = "\(fileExtension)_w"
                                image = NSImage.init(named: name)
                                if image == nil {
                                    image = NSImage(named: "- - -_w")
                                }
                            }
                        
                        case .download:
                            for view in cellView.subviews {
                                if let progressBar = view as? NSProgressIndicator {
                                    progressBar.stopAnimation(self)
                                    progressBar.isHidden = true
                                }
                            }
                            switch status {
                                case.waiting:
                                    let name = "\(fileExtension)_w"
                                    image = NSImage.init(named:  name)
                                    if image == nil {
                                        image = NSImage(named: "- - -_w")
                                }
                                case .pending:
                                    let name = "\(fileExtension.uppercased())_G"   //_protected"
                                    image = NSImage.init(named: name)
                                    if image == nil {
                                        image = NSImage(named:"---_g")
                                    }
                                    iconImage.imageAlignment = .alignRight
                                case .syncing:
                                    let name = "\(fileExtension)_u"
                                    image = NSImage.init(named:  name)
                                    if image == nil {
                                        image = NSImage(named: "- - -_u")
                                    }
                                    for view in cellView.subviews {
                                        if let progressBar = view as? NSProgressIndicator {
                                            progressBar.startAnimation(self)
                                            progressBar.isHidden = false
                                        }
                                    }
                                case .completed:
                                    let name = "\(fileExtension)_o"   //_protected"
                                    image = NSImage.init(named: name)
                                    if image == nil {
                                        image = NSImage(named:  "- - -_o")
                                    }
                                    for view in cellView.subviews {
                                        if let progressBar = view as? NSProgressIndicator {
                                            progressBar.stopAnimation(self)
                                            progressBar.isHidden = true
                                            
                                        }
                                    }
                                case .failed:
                                    let name = "\(fileExtension)_w"
                                    image = NSImage.init(named:  name)
                                    if image == nil {
                                        image = NSImage(named: "- - -_w")
                                    }
                            }
                    }
                } else {
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named:  "- - -_w")
                    }
                }
                
                iconImage.image = image
            }
            
            if let nameLbl = cellView.viewWithTag(1) as? NSTextField {
                nameLbl.textColor = NSColor.color(withHexColor: "#353535")
                nameLbl.stringValue = displayData[row].file.name
                
                 nameLbl.translatesAutoresizingMaskIntoConstraints = false
                
                if let iconImage = cellView.viewWithTag(0) as? NSImageView {
                    if self.orderType == .allOffline {
                        let c1 = nameLbl.leadingAnchor.constraint(equalTo:iconImage.trailingAnchor, constant: 10)
                        let c2 = nameLbl.centerYAnchor.constraint(equalTo: cellView.centerYAnchor, constant: -8)
                        let c3 = nameLbl.leadingAnchor.constraint(equalTo:iconImage.trailingAnchor, constant: 10)
                        let c4 = nameLbl.centerYAnchor.constraint(equalTo: cellView.centerYAnchor, constant: 0)
                        NSLayoutConstraint.deactivate([c3,c4])
                        NSLayoutConstraint.activate([c1,c2])
                      
                    }else{
                        let c1 = nameLbl.leadingAnchor.constraint(equalTo:iconImage.trailingAnchor, constant: 10)
                        let c2 = nameLbl.centerYAnchor.constraint(equalTo: cellView.centerYAnchor, constant: -8)

                        let c3 = nameLbl.leadingAnchor.constraint(equalTo:iconImage.trailingAnchor, constant: 10)
                        let c4 = nameLbl.centerYAnchor.constraint(equalTo: cellView.centerYAnchor, constant: 0)
                           NSLayoutConstraint.deactivate([c1,c2])
                        NSLayoutConstraint.activate([c3, c4])
                    }
                }
            }
            
            if let sourcePathLabel = cellView.viewWithTag(2) as? NSTextField{
                
                if self.orderType == .allOffline {
                    sourcePathLabel.isHidden = false
                    var sourcePath = ""
                    let fileName = displayData[row].file.name
                    if  displayData[row].file is NXShareWithMeFile {
                        sourcePath = "SIDERBAR_NAME_SHAREDWITHME_NOBLANK".localized
                        sourcePath.append(fileName)
                    }else if  displayData[row].file is NXMyVaultFile {
                        sourcePath =  "SIDERBAR_NAME_MYVAULT".localized  + "://"
                        sourcePath.append(fileName)
                    }else if displayData[row].file is NXProjectFileModel {
                        let projectFile = displayData[row].file as! NXProjectFileModel
                        let projectSourcePath = projectFile.fullServicePath
                        sourcePath = "SIDERBAR_NAME_PROJECT".localized  + "://"
                        sourcePath.append(projectFile.project!.name)
                        sourcePath.append(projectSourcePath)
                    } else if let file = displayData[row].file as? NXWorkspaceFile {
                        sourcePath = "SIDERBAR_NAME_WORKSPACE".localized + ":/" + file.fullServicePath
                    }
                    sourcePathLabel.stringValue = sourcePath
                }else{
                    sourcePathLabel.stringValue = ""
                    sourcePathLabel.isHidden = true
                }
            }
        } else if identifier.rawValue == "fileLocation" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                if (displayData[row].file.isOffline || (displayData[row].file.isKind(of: NXNXLFile.self) && !displayData[row].file.isKind(of: NXMyVaultFile.self) && !displayData[row].file.isKind(of: NXShareWithMeFile.self))){
                    cell.textField?.stringValue = "FILE_INFOLOCATION_LOCATION".localized
                }else {
                    cell.textField?.stringValue = "FILE_INFO_LOCATION_ONLINE".localized
                }
                
            }
            
        } else if identifier.rawValue == "dateModified" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                
                if tableColumn?.title == "FILE_INFO_SHAREDTIME".localized, let shareWithMeFile = displayData[row].file.sdmlBaseFile as? SDMLShareWithMeFile {
                    cell.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: shareWithMeFile.getSharedDate())
                } else {
                    cell.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: displayData[row].file.lastModifiedDate as Date)
                }
            }
            
        } else if identifier.rawValue == "size" {
            if let cell = cellView as? NSTableCellView {
                let str = NXCommonUtils.formatFileSize(fileSize: displayData[row].file.size, precision: 2)
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = str
            }
        } else if identifier.rawValue == "sharedWith" {
            if let cell = cellView as? NSTableCellView {
                
                if tableColumn?.title == "FILE_INFO_SHAREDWITH".localized {
                    
                    var sharedWith = ""
                    if let file = displayData[row].file as? NXNXLFile, let recipients = file.recipients {
                        sharedWith = recipients.joined(separator: ",")
                        
                    }
                    
                    let grayAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.init(colorWithHex: "#828282")!]
                    cell.textField?.attributedStringValue = NSAttributedString.init(string: sharedWith, attributes: grayAttriDic)
                    
                }else if tableColumn?.title == "FILE_INFO_SHAREDBY".localized {
                    if let file = displayData[row].file as? NXShareWithMeFile {
                        let grayAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.init(colorWithHex: "#828282")!]
                        cell.textField?.attributedStringValue = NSAttributedString.init(string: file.shareBy ?? "", attributes: grayAttriDic)
                    }
                }else if tableColumn?.title == "FILE_INFO_TYPE".localized {
                    var typeStr = ""
                    if displayData[row].file is NXShareWithMeFile {
                        typeStr = "SIDERBAR_NAME_SHAREDWITHME".localized
                    }else if displayData[row].file is NXMyVaultFile {
                        typeStr = "SIDERBAR_NAME_MYVAULT".localized
                    }else if displayData[row].file is NXProjectFileModel {
                        typeStr = "SIDERBAR_NAME_PROJECT".localized
                    } else if displayData[row].file is NXWorkspaceBaseFile {
                        typeStr = "SIDERBAR_NAME_WORKSPACE".localized
                    }
                    cell.textField?.textColor = NSColor.color(withHexColor: "#828282")
                    cell.textField?.stringValue = typeStr
                }
                
            }
            
        }else {
            assert(true)
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CustomRowView"), owner: nil) as? NXCustomRowView else {
            let rowView = NXCustomRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "CustomRowView")
            return rowView
        }
        return rowView
    }
    
    func tableView(_ tableView: NSTableView,
                   sizeToFitWidthOfColumn column: Int) -> CGFloat
    {
        return NXCommonUtils.resizeColumn(tableview: tableView, columnIndex: column)
    }
}

extension NXMyVaultViewController: NXLocalListItemContextMenuOperationDelegate {
    func menuItemClicked(type: NXLocalListItemContextMenuOperation, value: Any?) {
        switch type {
        case .viewFileInfo:
            if let file = value as? NXSyncFile {
                viewFileInfo(file: file)
            }
            
        case .openWeb:
            NXCommonUtils.openWebsite()
            
        case .remove:
            if let file = value as? NXSyncFile {
                removeFileManual(file: file, isNotifi: false)
            }
            
        case .viewFile:
            guard let file = value as? NXSyncFile else {
                return
            }
            
            viewFile(file: file)
            
        case .share:
            guard let file = value as? NXSyncFile else {
                return
            }
            
            shareRecipients(file: file)
        case .download:
            guard let file = value as? NXSyncFile else {
                return
            }
            makeOffline(file: file)

        case .online:
            guard let file = value as? NXSyncFile else {
                return
            }
            
            makeUnOffline(file: file)
            
        case .addFileToProject:
            guard let file = value as? NXSyncFile, let nxFile = file.file as? NXProjectFileModel else {
                return
            }
            if nxFile.isTagFile ?? false && nxFile.rights?.contains(.extract) ?? false {
                self.delegate?.addFileToProject(nxlFile: nxFile)
            } else {
                NSAlert.showAlert(withMessage: "You are not authorized to perform this operation.")
                break
            }
            
        default:
            break
        }
    }
}

extension NXMyVaultViewController: NXHomeShareVCDelegate {
    func shareFinish(isNewCreated: Bool, files: [NXNXLFile]) {
        refresh()
    }
}

