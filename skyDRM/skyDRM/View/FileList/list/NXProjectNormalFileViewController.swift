////
////  NXProjectNormalFileViewController.swift
////  skyDRM
////
////  Created by William (Weiyan) Zhao on 2019/3/20.
////  Copyright © 2019 nextlabs. All rights reserved.
////
//
import Cocoa
import SDML
protocol NXProjectNormalFileViewControllerDelegate: class {
    func openNewFolder(item:Any)
    func addFileToProjectOfNormal(nxlFile: NXProjectFileModel)
    
}
class NXProjectNormalFileViewController:NSViewController {

    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var listEmptyView: NSView!
    @IBOutlet weak var name: NSTableColumn!
    @IBOutlet weak var fileLocation: NSTableColumn!
    @IBOutlet weak var dateModified: NSTableColumn!
    @IBOutlet weak var size: NSTableColumn!
    @IBOutlet weak var emptyFolderLab: NSTextField!
     
    var data = NXProjectFileModel() {
        didSet {
            self.reloadData(isRefresh: true)
        }
    }
    var orderType: NXListType = .projectFile
    // Display file data.
    @objc dynamic var displayData = [NXSyncFile]()
    @objc dynamic var file = [NXSyncFile]()
            var folder = [NXSyncFile]()
    @objc dynamic var displayCount: Int {
        get {
            return displayData.count
        }
    }
    
    // Configure
    var sortOrder = NXListOrder.dateModified
    var sortAscending = false
    var searchString = ""
    
    weak var delegate:NXProjectNormalFileViewControllerDelegate?

    
    var selectedFile: NXSyncFile? {
        let row = fileTableView.selectedRow
        if row == -1 {
            return nil
        }
        return displayData[row]
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        fileTableView.allowsColumnReordering = false
        listEmptyView.isHidden = true
        locationed()
        
        addObserver()
    }
    
    deinit {
        removeObserver()
    }
    // MARK:ChangeLanuages
    fileprivate func locationed() {
        name.title = "FILE_INFO_FILENAME".localized
        fileLocation.title = "FILE_INFO_FILELOCATION".localized
        dateModified.title = "FILE_INFO_MODIFIEDTIME".localized
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
        if let selectedRow =  displayData[mouseRow].file as? NXProjectFileModel {
            if selectedRow.isFolder {
                return
            }
        }
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
    
    fileprivate func reloadData(isRefresh: Bool) {
        if isRefresh {
            self.sortOrder = .dateModified
            self.sortAscending = false
        }
        
        file.removeAll()
        folder.removeAll()
        for projectFile in data.subfiles {
            if let nxProjectFile = projectFile.file as? NXProjectFileModel {
                if nxProjectFile.isFolder  {
                    folder.append(projectFile)
                } else {
                    file.append(projectFile)
                }
            } else {
                file.append(projectFile)
            }
        }
        self.sortContentOrderBy(self.sortOrder, ascending: self.sortAscending)
        displayEmptyView(isShow:data.subfiles.isEmpty)
        fileTableView.reloadData()
    }
}
// MARK: Sort.

extension NXProjectNormalFileViewController {
    fileprivate func filterCompletion() {
        displayData = data.subfiles
    }
    fileprivate func filterWithSearchString() {
        if searchString.isEmpty {
            displayData = data.subfiles
        } else {
            let filterData = data.subfiles.filter() {$0.file.name.localizedCaseInsensitiveContains(searchString)}
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
            sortedFiles = files.sorted {
            if $0.file.lastModifiedDate == $1.file.lastModifiedDate { return $0.file.name.localizedLowercase < $1.file.name.localizedLowercase}
                return itemComparator(lhs: $0.file.lastModifiedDate as Date, rhs: $1.file.lastModifiedDate as Date, ascending: ascending)
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
            sortedFiles = files.sorted {
                return ($0.file.name.compare($1.file.name, options: .caseInsensitive) == .orderedAscending)
            }
        }
        return sortedFiles
    }
    
    fileprivate func sortContentOrderBy(_ sortOrder: NXListOrder, ascending: Bool) {
        self.displayData = self.folder +  getOrderFiles(files: self.file, sortOrder: sortOrder, ascending: ascending)
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
    }
    
    func sortTableviewOrderByName(){
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

extension NXProjectNormalFileViewController {
    
    fileprivate func initView() {
        initTableView()
        initSortDescriptor()
    }
    
    fileprivate func initTableView() {
        fileTableView.target = self
        fileTableView.doubleAction = #selector(tableViewDoubleClick(_:))
        fileTableView.dataSource = self
        fileTableView.delegate = self
    }
    
    @objc fileprivate func tableViewDoubleClick(_ sender: Any) {
        openSelectedFileOropenFolder()
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

extension NXProjectNormalFileViewController {
    func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .projectProtected)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadProject)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .startUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .stopUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploaded)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadFailed)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .removeFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .updateProjectFile)
    }
    
    fileprivate func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .projectProtected {
            if let projectFile = notification.object as? NXLocalProjectFileModel  {
                if projectFile.projectId != self.data.project?.id {
                    return
                }
                
                if projectFile.parentFileId != self.data.fileId {
                    return
                }
                
                DispatchQueue.main.async {
                    self.reloadData(isRefresh: false)
                }
            }
        } else if notification.nxNotification == .uploadProject ||
            notification.nxNotification == .startUpload ||
            notification.nxNotification == .stopUpload {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    self.displayStatusChange(file: file)
                }
            }
        } else if notification.nxNotification == .uploaded {
            if let syncFile = notification.object as? NXSyncFile,
                let projectFile = syncFile.file as? NXProjectFileModel {
                
                if projectFile.project?.id != self.data.project?.id {
                    return
                }
                
                let parentPathID = projectFile.parentFileID
                if parentPathID != self.data.fileId {
                    return
                }
                
                reloadData(isRefresh: false)
            }
        } else if notification.nxNotification == .uploadFailed {
            if let file = notification.object as? NXSyncFile,
                let error = notification.userInfo?["error"] as? Error {
                DispatchQueue.main.async {
                    self.displayStatusChange(file: file)
                    self.displayUploadError(error: error)
                }
            }
        } else if notification.nxNotification == .removeFile {
            if let file = notification.object as? NXSyncFile{
                if let projectFile = file.file as? NXLocalProjectFileModel  {
                    if projectFile.projectId != self.data.project?.id {
                        return
                    }
                    
                    if projectFile.parentFileId != self.data.fileId {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.reloadData(isRefresh: false)
                    }
                }
            }
        } else if notification.nxNotification == .updateProjectFile {
            if let file = notification.object as? NXSyncFile{
                DispatchQueue.main.async {
                    if let currentFile = self.getCurrentFile(file: file) {
                        self.updateProjectFile(file: currentFile, newFile: file)
                    }
                }
            }
        }
    }
    
    func getCurrentFile(file: NXSyncFile) -> NXSyncFile? {
        for (index, item) in self.data.subfiles.enumerated() {
            if let nxFile = item.file.sdmlBaseFile as? SDMLNXLFile, let removeFile = file.file.sdmlBaseFile as? SDMLNXLFile {
                if nxFile.getDUID() == removeFile.getDUID() {
                    return self.data.subfiles[index]
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

extension NXProjectNormalFileViewController {
    
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
    
    func removeFileWithFile(file: NXSyncFile, isUpload: Bool) {
        
        for (index, item) in self.data.subfiles.enumerated() {
            if item == file {
                self.data.subfiles.remove(at: index)
                self.displayEmptyView(isShow: data.subfiles.isEmpty)
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
    
    func removeFileAutomatic(file: NXSyncFile) {
        for (index, item) in self.data.subfiles.enumerated() {
            if item == file {
                self.data.subfiles.remove(at: index)
                self.displayEmptyView(isShow: data.subfiles.isEmpty)
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
    }
    
    func updateProjectFile(file: NXSyncFile, newFile: NXSyncFile) {
        var currentIndex = 0
        for (index, item) in self.data.subfiles.enumerated() {
            if item == file {
                self.data.subfiles[index] = newFile
                currentIndex = index
                break
            }
        }
        
        for (index, item) in self.displayData.enumerated() {
            if item == file {
                self.displayData[index] = newFile
                break
            }
        }
        let columns = IndexSet.init(0..<self.fileTableView.numberOfColumns)
        self.fileTableView.reloadData(forRowIndexes: [currentIndex], columnIndexes: columns)
    }
    
    func viewFileInfo(file: NXSyncFile) {
        let fileInfoViewController = FileInfoViewController(nibName:  "FileInfoViewController", bundle: nil)
        fileInfoViewController.file = file.file as? NXNXLFile
        self.presentAsModalWindow(fileInfoViewController)
    }
    
    func makeOffline(file:NXSyncFile) {
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
        NXClient.getCurrentClient().makeFileOfflineOfProject(file: file) { [weak self] (file, error) in
            file?.file.fileStatus.remove(.downloading)
            if error == nil {
                DispatchQueue.main.async {
                self?.fileTableView.reloadData()
                }
                NotificationCenter.post(notification: .download, object: file, userInfo: nil)
                NotificationCenter.post(notification: .allOfflineAddFile, object: file)
            } else {
                let message = "FILE_OPERATION_DOWNLOAD_FAILED".localized
                NSAlert.showAlert(withMessage: message)
                file?.syncStatus?.status = .pending
                DispatchQueue.main.async {
                    self?.fileTableView.reloadData()
                }
                NotificationCenter.post(notification: .download, object: file, userInfo: ["error":error!])
            }
        }
        self.fileTableView.reloadData()
        NotificationCenter.post(notification: .download, object: file, userInfo: nil)
    }
    
    func makeUnOffline(file:NXSyncFile) {
        NXClient.getCurrentClient().makeFileOnlineOfProject(file: file, completion: {[weak self] (file, error) in
            if error == nil {
                NotificationCenter.post(notification: .unOfflineAndRemoveFile, object: file)
                DispatchQueue.main.async {
                      self?.fileTableView.reloadData()
                }
            }else {
                print(error as Any)
            }
        })
    }
    
    func stopUploadAll() {
        NXSyncManager.shared.stopUploadAll()
    }
}

// MARK: - Public methods.

extension NXProjectNormalFileViewController {
    
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
    func openSelectedFileOropenFolder() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        let file = displayData[self.fileTableView.selectedRow]
        if let newFile  = file.file as? NXProjectFileModel, newFile.isFolder {
            delegate?.openNewFolder(item: file)
        } else {
            if file.file.fileStatus.contains(.downloading) || file.file.fileStatus.contains(.uploading) {
                return
            }
            viewFile(file: file)
        }
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
    
    func refresh() {
        self.fileTableView.reloadData()
    }
}

extension NXProjectNormalFileViewController: NSTableViewDataSource {
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

extension NXProjectNormalFileViewController: NSTableViewDelegate {
    
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
                        switch status {
                        case.waiting:
                            let name = "\(fileExtension)_w"
                            image = NSImage.init(named:name)
                            if image == nil {
                                image = NSImage(named:  "- - -_w")
                            }
                        case .pending:
                            let name = "\(fileExtension)_w"
                            image = NSImage.init(named:name)
                            if image == nil {
                                image = NSImage(named:  "- - -_w")
                            }
                        case .syncing:
                            let name = "\(fileExtension)_u"
                            image = NSImage.init(named:  name)
                            if image == nil {
                                image = NSImage(named: "- - -_u")
                            }
                        case .completed:
                            let name = "\(fileExtension)_d"
                            image = NSImage.init(named:  name)
                            if image == nil {
                                image = NSImage(named:  "- - -_d")
                            }
                        case .failed:
                            let name = "\(fileExtension)_w"
                            image = NSImage.init(named:name)
                            if image == nil {
                                image = NSImage(named:  "- - -_w")
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
                            image = NSImage.init(named:name)
                            if file.file is NXProjectFileModel {
                                if let newFile = file.file as? NXProjectFileModel {
                                    if newFile.isFolder {
                                        image = NSImage.init(named:NSImage.folderName)
                                    }
                                }
                            }
                            if image == nil {
                                image = NSImage(named: "---_g")
                            }
                            iconImage.imageAlignment = .alignRight
                        case .syncing:
                            let name = "\(fileExtension)_u"
                            image = NSImage.init(named: name)
                            if image == nil {
                                image = NSImage(named:  "- - -_u")
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
                                image = NSImage(named: "- - -_o")
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
                                image = NSImage(named:  "- - -_w")
                            }
                        }
                    }
                }else {
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
            }
            
        } else if identifier.rawValue == "fileLocation" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                if (displayData[row].file.isOffline || (displayData[row].file.isKind(of: NXNXLFile.self) && !displayData[row].file.isKind(of: NXMyVaultFile.self) && !displayData[row].file.isKind(of: NXShareWithMeFile.self) && !displayData[row].file.isKind(of: NXProjectFileModel.self) )){
                    cell.textField?.stringValue = "FILE_INFOLOCATION_LOCATION".localized
                }else {
                    cell.textField?.stringValue = "FILE_INFO_LOCATION_ONLINE".localized
                }
                
            }
            
        } else if identifier.rawValue == "dateModified" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: displayData[row].file.lastModifiedDate as Date)
            }
            
        } else if identifier.rawValue == "size" {
            if let cell = cellView as? NSTableCellView {
                let str = NXCommonUtils.formatFileSize(fileSize: displayData[row].file.size, precision: 2)
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = str
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

extension NXProjectNormalFileViewController: NXLocalListItemContextMenuOperationDelegate {
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
            guard let _ = value as? NXSyncFile else {
                return
            }
            
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
            
            self.delegate?.addFileToProjectOfNormal(nxlFile: nxFile)
            
        default:
            break
        }
    }
}



