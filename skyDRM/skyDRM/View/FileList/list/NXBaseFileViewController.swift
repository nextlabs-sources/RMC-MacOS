//
//  NXWorkspaceViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/26/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Cocoa

protocol NXBaseFileViewControllerDelegate: NSObjectProtocol {
    func openFolder(file: NXFileBase)
}

class NXBaseFileViewController: NSViewController {
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var listEmptyView: NSView!
    
    weak var delegate: NXBaseFileViewControllerDelegate?
    var folder: NXFileBase?
    var data = [NXFileBase]() {
        didSet {
            displayData = NXCommonUtils.sort(files: self.data, type: sortOrder, ascending: sortAscending)
        }
    }
    
    @objc dynamic var displayData = [NXFileBase]()
    @objc dynamic var displayCount: Int {
        get {
            return displayData.count
        }
    }
    
    var sortOrder = NXListOrder.dateModified
    var sortAscending = false
    var searchString = ""
    
    var selectedFile: NXFileBase? {
        let row = fileTableView.selectedRow
        if row == -1 {
            return nil
        }
        return displayData[row]
    }
    
    deinit {
    }
    
    override func viewDidLoad() {
       super.viewDidLoad()
   
       initView()
   }
    
    private func initView() {
        initTableView()
        initEmptyView()
    }

    private func initTableView() {
        fileTableView.target = self
        fileTableView.doubleAction = #selector(tableViewDoubleClick(_:))
        fileTableView.dataSource = self
        fileTableView.delegate = self
        
        let setTitle: (String, String) -> () = { id, value in
            let index = self.fileTableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id))
            let column = self.fileTableView.tableColumns[index]
            column.title = value
        }
        setTitle("name", "FILE_INFO_FILENAME".localized)
        setTitle("fileLocation", "FILE_INFO_FILELOCATION".localized)
        setTitle("dateModified", "FILE_INFO_MODIFIEDTIME".localized)
        setTitle("size", "FILE_INFO_SIZE".localized)
        
        initSortDescriptor()
        fileTableView.allowsColumnReordering = true
    }
    
    private func initSortDescriptor() {
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: false)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dateModified")) {
            let sortDescriptor = NSSortDescriptor.init(key: "dateModified", ascending: false)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "size")) {
            let sortDescriptor = NSSortDescriptor.init(key: "size", ascending: false)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileLocation")) {
            let sortDescriptor = NSSortDescriptor.init(key: "fileLocation", ascending: false)
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
    }
    
    private func initEmptyView() {
        listEmptyView.isHidden = true
        if let _ = listEmptyView.viewWithTag(0) as? NSImageView {
        }
        if let label = listEmptyView.viewWithTag(1) as? NSTextField {
            label.stringValue = "FILE_INFO_EMPTY_PROJECT".localized
        }
    }
}

// MARK: - Display

extension NXBaseFileViewController {
    
    func displayEmptyView(isShow: Bool) {
        if isShow {
            listEmptyView.isHidden = false
        } else {
            listEmptyView.isHidden = true
        }
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

// MARK: - List operation.

extension NXBaseFileViewController {
    
    func loadData(folder: NXFileBase?, files: [NXFileBase]) {
        self.folder = folder
        self.data = files
        
        displayEmptyView(isShow: self.displayData.count == 0)
        self.fileTableView.reloadData()
    }
    
    func search(include: String) {
        searchString = include
        let filterData: [NXFileBase]
        if searchString.isEmpty {
            filterData = self.data
        } else {
            filterData = data.filter() { $0.name.localizedCaseInsensitiveContains(searchString) }
        }
        
        self.displayData = NXCommonUtils.sort(files: filterData, type: sortOrder, ascending: sortAscending)
        self.fileTableView.reloadData()
    }
    
    func sort(type: NXListOrder) {
        sortOrder = type
        sortAscending = !sortAscending
        self.displayData = NXCommonUtils.sort(files: self.displayData, type: sortOrder, ascending: sortAscending)
        
        if let tableColumn = fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: sortOrder.rawValue)) {
            tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: sortOrder.rawValue, ascending: sortAscending)
        }
        
        self.fileTableView.reloadData()
    }
    
}

// MARK: - File operation.

extension NXBaseFileViewController: NXLocalListItemContextMenuOperationDelegate {
    
    @objc func tableViewDoubleClick(_ sender: Any) {
        openSelectedFileOrOpenFolder()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        let mousePoint = view.convert(event.locationInWindow, from: nil)
        let mouseInTable = view.convert(mousePoint, to: self.fileTableView)
        let mouseRow = fileTableView.row(at: mouseInTable)
        if mouseRow == -1 {
            return
        }
        selectRow(row: mouseRow)
        
        let file = displayData[mouseRow]
        if file.isFolder {
            return
        }
        
        let listItemContextMenu = NXLocalListItemContextMenu(title: "")
        listItemContextMenu.operationDelegate = self
        let syncFile = NXSyncFile(file: file)
        syncFile.syncStatus = file.status
        listItemContextMenu.file = syncFile
        listItemContextMenu.popUp(positioning: listItemContextMenu.item(at: 0), at: mousePoint, in: self.view)
    }
    
    func menuItemClicked(type: NXLocalListItemContextMenuOperation, value: Any?) {
        switch type {
        case .viewFileInfo:
            if let file = value as? NXSyncFile {
                viewFileInfo(file: file.file)
            }
            
        case .openWeb:
            NXCommonUtils.openWebsite()
            
        case .remove:
            if let file = value as? NXSyncFile {
                removeFileManual(file: file.file, isNotifi: false)
            }
            
        case .viewFile:
            guard let file = value as? NXSyncFile else {
                return
            }
            
            viewFile(file: file.file)
            
        case .download:
            guard let file = value as? NXSyncFile else {
                return
            }
            markOffline(file: file.file)
            
        case .online:
            guard let file = value as? NXSyncFile else {
                return
            }
            unmarkOffline(file: file.file)
            
        default:
            break
        }
    }
    
    func openSelectedFileOrOpenFolder() {
        if self.fileTableView.selectedRow == -1 {
            return
        }
        
        let file = displayData[self.fileTableView.selectedRow]
        if file.isFolder {
            delegate?.openFolder(file: file)
        }  else {
            if file.fileStatus.contains(.downloading) || file.fileStatus.contains(.uploading) {
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
    
    func viewFile(file: NXFileBase) {
        NXFileRenderManager.shared.viewCache(file: file)
        
    }
    func removeFileManual(file: NXFileBase, isNotifi: Bool) {
        if isNotifi {
            self.removeFileWithFile(file: file)
            NotificationCenter.post(notification: .removeFile, object: file)
            return
        }
        NSAlert.showAlert(withMessage: "CONFIRM_DELETING_FILE".localized, confirmButtonTitle: "Remove", cancelButtonTitle: "Cancel") { (type) in
            if type == .sure {
                self.removeFileWithFile(file: file)
                NotificationCenter.post(notification: .removeFile, object: file)
            }
        }
    }
    
    func removeFileWithFile(file: NXFileBase) {
        for (index, item) in self.data.enumerated() {
            if item == file {
                self.data.remove(at: index)
                break
            }
        }
        self.fileTableView.reloadData()
        _ = NXClient.getCurrentClient().deleteFile(file: file, isUpload: false)
    }
    
    func viewFileInfo(file: NXFileBase) {
        let fileInfoViewController = FileInfoViewController(nibName:  "FileInfoViewController", bundle: nil)
        fileInfoViewController.file = file as? NXNXLFile
        self.presentAsModalWindow(fileInfoViewController)
    }
    
    @objc func markOffline(file: NXFileBase) {
        file.fileStatus.insert(.downloading)
        file.status?.status = .syncing
        self.fileTableView.reloadData(forRowIndexes: [self.fileTableView.selectedRow], columnIndexes: [0])
        NotificationCenter.post(notification: .download, object: file, userInfo: nil)
        
    }
    
    @objc func unmarkOffline(file: NXFileBase) {}
}

// MARK: - TableView delegate

extension NXBaseFileViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard
        let sortDescriptor = tableView.sortDescriptors.first,
        let key = sortDescriptor.key,
        let order = NXListOrder(rawValue: key)
        else {
            return
        }
        sortOrder = order
        sortAscending = sortDescriptor.ascending
        
        self.displayData = NXCommonUtils.sort(files: self.displayData, type: order, ascending: sortDescriptor.ascending)
        tableView.reloadData()
        
    }
}

extension NXBaseFileViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self)
            else { return nil }
        
        let file = displayData[row]
        if identifier.rawValue == "name" {
            if let iconImage = cellView.viewWithTag(0) as? NSImageView {
                
                // Progress bar.
                for view in cellView.subviews {
                    if let progressBar = view as? NSProgressIndicator {
                        
                        if file.status?.type == .download,
                            file.status?.status == .syncing {
                            progressBar.isHidden = false
                            progressBar.startAnimation(self)
                        } else {
                            progressBar.isHidden = true
                            progressBar.stopAnimation(self)
                        }
                        
                        break
                    }
                }
                
                iconImage.imageAlignment = .alignRight
                let image = NXCommonUtils.getIconImage(file: file)
                iconImage.image = image
            }
            
            if let nameLbl = cellView.viewWithTag(1) as? NSTextField {
                nameLbl.textColor = NSColor.color(withHexColor: "#353535")
                nameLbl.stringValue = file.name
            }
            
        } else if identifier.rawValue == "fileLocation" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                if (file.isOffline) {
                    cell.textField?.stringValue = "FILE_INFOLOCATION_LOCATION".localized
                } else {
                    cell.textField?.stringValue = "FILE_INFO_LOCATION_ONLINE".localized
                }
                
            }
            
        } else if identifier.rawValue == "dateModified" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
            }
            
        } else if identifier.rawValue == "size" {
            if let cell = cellView as? NSTableCellView {
                let str = NXCommonUtils.formatFileSize(fileSize: file.size, precision: 2)
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
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40.0
    }
}
