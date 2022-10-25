//
//  NXLocalMainFileListViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 20/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXLocalMainFileListViewControllerDelegate: class {
    func protect()
    func share()
}

class NXLocalMainFileListViewController: NSViewController {
    
    fileprivate struct Constant {
        static let kListEmptyViewNibName = "NXLocalListEmptyViewController"
    }
    
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var listEmptyView: NSView!
    @IBOutlet weak var name: NSTableColumn!
    @IBOutlet weak var fileLocation: NSTableColumn!
    @IBOutlet weak var dateModified: NSTableColumn!
    @IBOutlet weak var shareWith: NSTableColumn!
    @IBOutlet weak var size: NSTableColumn!
    
    // All file data.
    fileprivate var data = [NXSyncFile]()
    // Display file data.
    @objc dynamic fileprivate var displayData = [NXSyncFile]()
    
    @objc dynamic var displayCount: Int {
        get {
            return displayData.count
        }
    }
    
    // Configure
    fileprivate var sortOrder = NXListOrder.dateModified
    fileprivate var sortAscending = false
    fileprivate var searchString = ""
    
    weak var delegate: NXLocalMainFileListViewControllerDelegate?
    
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
        
        initView()
        initData()
        locationed()
        
        addObserver()
        
        if NXClientUser.shared.setting.getIsAutoUpload() {
            uploadAll()
        }
    }
    
    deinit {
        removeObserver()
    }
    // MARK:ChangeLanuages
    fileprivate func locationed() {
        //  name.title = String.init(format: "FILE_INFO_FILENAME".localized, 0)
        name.title = "FILE_INFO_FILENAME".localized
        fileLocation.title = "FILE_INFO_FILELOCATION".localized
        dateModified.title = "FILE_INFO_MODIFIEDTIME".localized
        shareWith.title = "FILE_INFO_SHAREDWITH".localized
        size.title = "FILE_INFO_SIZE".localized
    }
    
    // MARK: System action.
    override func rightMouseDown(with event: NSEvent) {
        let mousePoint = self.view.convert(event.locationInWindow, from: nil)
        let mouseInTable = self.view.convert(mousePoint, to: self.fileTableView)
        let mouseRow = self.fileTableView.row(at: mouseInTable)
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

extension NXLocalMainFileListViewController {
    fileprivate func filterWithSearchString() {
        if searchString.isEmpty {
            displayData = data
        } else {
            let filterData = data.filter() {$0.file.name.localizedCaseInsensitiveContains(searchString)}
            displayData = filterData
        }
    }
    
    fileprivate func getOrderFiles(files: [NXSyncFile], sortOrder: NXListOrder, ascending: Bool) -> [NXSyncFile] {
        let sortedFiles: [NXSyncFile]
        switch sortOrder {
        case .name:
            sortedFiles = files.sorted {
               // return itemComparator(lhs: $0.file.name, rhs: $1.file.name, ascending: ascending)
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
    
    func sortTableviewOrderByName(){
        filterWithSearchString()
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.name, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            } else {
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
}

extension NXLocalMainFileListViewController {
    
    func initData() {
        reloadData(isRefresh: true)
    }
    
    private func reloadData(isRefresh: Bool) {
        if isRefresh {
            self.sortOrder = .dateModified
            self.sortAscending = false
        }
        
        self.data = NXMemoryDrive.sharedInstance.getOutBox()
        self.displayData = self.getOrderFiles(files: self.data, sortOrder: self.sortOrder, ascending: self.sortAscending)
        // Update UI.
        self.displayEmptyView(isShow: self.data.isEmpty)
        self.fileTableView.reloadData()
    }
    
    fileprivate func initView() {
        initEmptyView()
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
  
    fileprivate func initEmptyView() {
        listEmptyView.isHidden = true
         let viewController = NXLocalListEmptyViewController(nibName: Constant.kListEmptyViewNibName, bundle: nil)
            viewController.view.frame = listEmptyView.bounds
            listEmptyView.addSubview(viewController.view)
            
            viewController.delegate = self
        addChild(viewController)
    }
    
    fileprivate func displayEmptyView(isShow: Bool) {
        if isShow {
            listEmptyView.isHidden = false
        } else {
            listEmptyView.isHidden = true
        }
    }
    
}

// MARK: Notification.

extension NXLocalMainFileListViewController {
    fileprivate func addObserver() {
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .myVaultProtected)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .projectProtected)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadMyvalut)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadProject)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .startUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .stopUpload)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploaded)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .uploadFailed)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .removeFile)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .renderFinish)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .workspaceProtected)
    }
    
    fileprivate func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func observeNotification(_ notification: Notification) {
        if (notification.nxNotification == .myVaultProtected || notification.nxNotification == .projectProtected || notification.nxNotification == .workspaceProtected) {
            DispatchQueue.main.async {
                self.reloadData(isRefresh: false)
            }
        } else if notification.nxNotification == .uploadMyvalut ||
            notification.nxNotification == .uploadProject ||
            notification.nxNotification == .startUpload ||
            notification.nxNotification == .stopUpload {
            if let file = notification.object as? NXSyncFile {
                DispatchQueue.main.async {
                    self.displayStatusChange(file: file)
                }
                
            }
        } else if notification.nxNotification == .uploaded {
            DispatchQueue.main.async {
                self.reloadData(isRefresh: false)
            }
            
        } else if notification.nxNotification == .uploadFailed {
            if let file = notification.object as? NXSyncFile,
                let error = notification.userInfo?["error"] as? Error {
                DispatchQueue.main.async {
                    self.displayStatusChange(file: file)
                    self.displayUploadError(error: error)
                }
            }
        }else if notification.nxNotification == .removeFile {
            DispatchQueue.main.async {
                self.initData()
            }
        } else if notification.nxNotification == .renderFinish {
            if let openedFile = notification.object as? NXFileBase {
                for file in self.data {
                    if file.file.getNXLID() == openedFile.getNXLID() {
                        if NXClientUser.shared.setting.getIsAutoUpload() {
                            self.uploadFile(file: file)
                        }
                        break
                    }
                }
                
            }
        }
    }
    
    fileprivate func displayUploadError(error: Error) {
        if let sdmlError = error as? SDMLError,
            case SDMLError.uploadFailed(reason: .storageExceeded) = sdmlError {
            NXToastWindow.sharedInstance?.toast("Storage exceeded")
        }
    }
    
    fileprivate func displayStatusChange(file: NXSyncFile) {
        for (index, displayFile) in displayData.enumerated() {
            if displayFile === file {
                let columns = IndexSet.init(0..<self.fileTableView.numberOfColumns)
                self.fileTableView.reloadData(forRowIndexes: [index], columnIndexes: columns)
                break
            }
        }
        
    }
}

// File Operations.

extension NXLocalMainFileListViewController {
    
    func viewFile(file: NXSyncFile) {
        NXFileRenderManager.shared.viewCache(file: file.file)
    }
    
    func removeFileManual(file: NXSyncFile, isNotifi: Bool) {
        if isNotifi {
            self.removeFileAutomatic(file: file, isUpload: false)
            NotificationCenter.post(notification: .removeFile, object: file)
            return
        }
        NSAlert.showAlert(withMessage: "CONFIRM_DELETING_FILE".localized, confirmButtonTitle: "Remove", cancelButtonTitle: "Cancel") { (type) in
            if type == .sure {
                self.removeFileAutomatic(file: file, isUpload: false)
                NotificationCenter.post(notification: .removeFile, object: file)
            }
        }
      
    }
    
    func removeFileAutomatic(file: NXSyncFile,isUpload: Bool) {
        for (index, item) in self.data.enumerated() {
            if item == file {
                self.data.remove(at: index)
                self.displayEmptyView(isShow: self.data.isEmpty)
                break
            }
        }
        
        for (index, item) in self.displayData.enumerated() {
            if item === file {
                self.displayData.remove(at: index)
                self.fileTableView.reloadData()
                break
            }
        }
        _ = NXClient.getCurrentClient().deleteFile(file: file.file, isUpload: isUpload)
    }
    
    func viewFileInfo(file: NXSyncFile) {
        if let nxlFile = file.file as? NXNXLFile {
            let fileInfoViewController = FileInfoViewController(nibName:  "FileInfoViewController", bundle: nil)
            fileInfoViewController.file = nxlFile
            self.presentAsModalWindow(fileInfoViewController)
        }
    }
    
    func uploadFile(file: NXSyncFile) {
        NXSyncManager.shared.upload(file: file)
    }
    
    func stopUploadFile(file: NXSyncFile) {
        NXSyncManager.shared.stopUpload(file: file)
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
    
    func uploadAll() {
        for file in data {
            NXSyncManager.shared.upload(file: file)
        }
    }
    
    func stopUploadAll() {
        NXSyncManager.shared.stopUploadAll()
    }
}

// MARK: - Public methods.

extension NXLocalMainFileListViewController {
    
    func uploadFile(files: [NXNXLFile]) {
        var uploadingFiles = [NXSyncFile]()
        for file in data {
            if let nxlFile = file.file as? NXNXLFile,
                files.contains(nxlFile) {
                uploadingFiles.append(file)
            }
        }
        
        for file in uploadingFiles {
            uploadFile(file: file)
        }
    }
    
    func getItemCount() -> Int {
        return displayCount
    }

    func filterCompletioned() {
        displayData = data
        self.fileTableView.reloadData()
    }
    
    func filter(with searchString: String) {
        self.searchString = searchString
        filterWithSearchString()
        self.fileTableView.reloadData()
    }
    
    
    func openSelectedFile() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        let file = displayData[self.fileTableView.selectedRow]
        if !file.file.fileStatus.contains(.uploading) {
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
    
    func uploadSelectedFile() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        uploadFile(file: file)
    }
    
    func stopUploadSelectedFile() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        stopUploadFile(file: file)
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
    
    func reloadFileList() {
        filterWithSearchString()
        sortContentOrderBy(self.sortOrder, ascending: self.sortAscending)
        self.fileTableView.reloadData()
    }
    
    func refresh() {
        self.fileTableView.reloadData()
    }
}

extension NXLocalMainFileListViewController: NSTableViewDataSource {
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

extension NXLocalMainFileListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self)
            else { return nil }
        // Setting subview content.
        if identifier.rawValue == "name" {
            if let iconImage = cellView.viewWithTag(0) as? NSImageView {
                let file = displayData[row]
                var image: NSImage?
                
                let fileExtension = NXCommonUtils.getOriginFileExtension(filename: file.file.name)
                if let status = file.syncStatus?.status {
                    switch status {
                    case .waiting:
                        let name = "\(fileExtension)_w"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named:  "- - -_w")
                        }
                    case .pending:
                        let name = "\(fileExtension)_w"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named: "- - -_w")
                        }
                    case .syncing:
                        let name = "\(fileExtension)_u"
                        image = NSImage.init(named:  name)
                        if image == nil {
                            image = NSImage(named:  "- - -_u")
                        }
                    case .completed:
                        let name = "\(fileExtension)_d"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named: "- - -_d")
                        }
                    case .failed:
                        let name = "\(fileExtension)_w"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named:  "- - -_w")
                        }
                    }
                } else {
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named:"- - -_w")
                    }
                }
                
                iconImage.image = image
            }
            
            if let nameLbl = cellView.viewWithTag(1) as? NSTextField {
                nameLbl.stringValue = displayData[row].file.name
                nameLbl.textColor = NSColor.color(withHexColor: "#353535")
            }
            
            if let sourcePathLabel = cellView.viewWithTag(2) as? NSTextField{
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
                }else if displayData[row].file is NXLocalProjectFileModel {
                    let projectFile = displayData[row].file as! NXLocalProjectFileModel
                    let fullServicePath = projectFile.projectName! + projectFile.fullServicePath + projectFile.name
                    let projectSourcePath = fullServicePath
                    sourcePath = "SIDERBAR_NAME_PROJECT".localized  + "://"
                    sourcePath.append(projectSourcePath)
                } else if let file = displayData[row].file as? NXWorkspaceLocalFile {
                    sourcePath = "SIDERBAR_NAME_WORKSPACE".localized + ":/" + (file.parent?.fullServicePath ?? "") + file.name
                } else if displayData[row].file is NXNXLFile {
                    sourcePath =  "SIDERBAR_NAME_MYVAULT".localized  + "://"
                    sourcePath.append(fileName)
                }else{
                    sourcePath.append(displayData[row].file.name)
                }
                sourcePathLabel.stringValue = sourcePath
            }
            
        } else if identifier.rawValue == "fileLocation" {
            if let cell = cellView as? NSTableCellView {
                if displayData[row].file.localFile {
                    cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                    cell.textField?.stringValue = "Local"
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
            
        } else if identifier.rawValue == "sharedWith" {
            if let cell = cellView as? NSTableCellView {
                var sharedWith = ""
                if let file = displayData[row].file as? NXNXLFile, let recipients = file.recipients {
                    sharedWith = recipients.joined(separator: ",")
                    
                }
                
                let grayAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.init(colorWithHex: "#828282")!]
                cell.textField?.attributedStringValue = NSAttributedString.init(string: sharedWith, attributes: grayAttriDic)
            }
            
        } else {
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

extension NXLocalMainFileListViewController: NXLocalListItemContextMenuOperationDelegate {
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
        default:
            break
        }
    }
}

extension NXLocalMainFileListViewController: NXLocalListEmptyViewControllerDelegate {
    func protect() {
        delegate?.protect()
    }
    
    func share() {
        delegate?.share()
    }
}

extension NXLocalMainFileListViewController: NXHomeShareVCDelegate {
    func shareFinish(isNewCreated: Bool, files: [NXNXLFile]) {
        refresh()
    }
}
extension NXLocalMainFileListViewController {
    
}
