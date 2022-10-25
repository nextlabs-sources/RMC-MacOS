//
//  NXMyVaultFileTableView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXMyVaultFileTableView: NSView, NSTableViewDataSource, NSTableViewDelegate {

    enum MyVaultFileListType {
        case allType
        case allFile
        case allShare
        case activeShare
        case protectFile
        case deleted
        case revokedFiles
        
    }
    
    var currentType: MyVaultFileListType = .allFile
    
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var tableScrollView: NSScrollView!
    @IBOutlet weak var emptyView: NSImageView!
    @IBOutlet weak var emptyLabel: NSTextField!
    
    var fileData = NSMutableArray()
    var backUpFileData = NSArray()
    var currentSearchData = NSArray()
    var searchStringForHightLight:String?
    
    weak var dataViewDelegate: NXDataViewDelegate? = nil
    
    private var curSortDescriptor:[NSSortDescriptor]? = nil
    
    fileprivate var fileMenu : NXFileMenuView! = nil
    fileprivate var curHoverFile: NXFileBase? = nil
    fileprivate var rightclickMenu: NXTableRightClickContextMenu?
    
    fileprivate let sortbyNameKey = "name"
    fileprivate let sortbyLastModifiedTimeKey = "lastModifiedTime"
    fileprivate let sortbySizeKey = "size"
    fileprivate let sortbyAliasKey = "boundService.serviceAlias"
    
    fileprivate let sortbySharedBy = "sharedBy"

    var currentSelectedMenuTittle:String? = ""
    
    private var inited = false
    
    fileprivate var hoverRow = -1
    
    var isSharedWithMe: Bool = false
    
    var isFavorite: Bool = false
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)

        // Drawing code here.
    }
    func sortbyFileName() {
        var sortDescriptors = fileTableView.sortDescriptors
        if sortDescriptors.isEmpty == false {
            if sortDescriptors[0].key == sortbyNameKey {
                sortDescriptors[0] = NSSortDescriptor(key: sortbyNameKey, ascending: !sortDescriptors[0].ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            }
            else {
                sortDescriptors = sortDescriptors.filter({return $0.key != sortbyNameKey})
                let newSort = NSSortDescriptor(key: sortbyNameKey, ascending: true)
                sortDescriptors.insert(newSort, at: sortDescriptors.startIndex)
            }
        }
        else {
            sortDescriptors = [NSSortDescriptor(key: sortbyNameKey, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        }
        fileTableView.sortDescriptors = sortDescriptors
    }
    func sortbyLastModified() {
        var sortDescriptors = fileTableView.sortDescriptors
        if sortDescriptors.isEmpty == false {
            if sortDescriptors[0].key == sortbyLastModifiedTimeKey {
                sortDescriptors[0] = NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: !sortDescriptors[0].ascending)
            }
            else {
                sortDescriptors = sortDescriptors.filter({return $0.key != sortbyLastModifiedTimeKey})
                let newSort = NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: true)
                sortDescriptors.insert(newSort, at: sortDescriptors.startIndex)
            }
        }
        else {
            sortDescriptors = [NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: true)]
        }
        fileTableView.sortDescriptors = sortDescriptors
    }
    func sortbyFileSize() {
        var sortDescriptors = fileTableView.sortDescriptors
        if sortDescriptors.isEmpty == false {
            if sortDescriptors[0].key == sortbySizeKey {
                sortDescriptors[0] = NSSortDescriptor(key: sortbySizeKey, ascending: !sortDescriptors[0].ascending)
            }
            else {
                sortDescriptors = sortDescriptors.filter({return $0.key != sortbySizeKey})
                let newSort = NSSortDescriptor(key: sortbySizeKey, ascending: true)
                sortDescriptors.insert(newSort, at: sortDescriptors.startIndex)
            }
        }
        else {
            sortDescriptors = [NSSortDescriptor(key: sortbySizeKey, ascending: true)]
        }
        fileTableView.sortDescriptors = sortDescriptors
        
    }
    
    @IBAction func fileNameClicked(_ sender: Any) {
        let obj = sender as! NSButton
        let index = Int((obj.identifier?.rawValue)!)
        Swift.print("clicked index: \(String(describing: index))")
        
        let curSelected = fileData.object(at: index!) as! NXFileBase
        
        
        if ((curSelected as? NXFolder) != nil)
        {
            clearData()
            
            dataViewDelegate?.folderClicked(folder:curSelected)
         
        }else if ((curSelected as? NXFile) != nil)
        {
            if let file = curSelected as? NXNXLFile,
                file.isDeleted == true {
                return
            }
            dataViewDelegate?.fileClicked(file:curSelected)
        }
    }
    
    override func viewDidMoveToSuperview()
    {
        super.viewDidMoveToSuperview()
        searchStringForHightLight = ""
    }
    
    func doWork(){
        if inited {
            return
        }
        
        let rect = NSRect(x: 0, y: 0, width: 200, height: 40)
        
        fileMenu = NXFileMenuView(frame: rect)
        fileMenu.delegate = self
        
        fileTableView.rowHeight = 40.0
        
        emptyLabel.isHidden = true
        emptyView.isHidden = true
        // handle sort
        for col in fileTableView.tableColumns {
            if (col.identifier.rawValue == "fileName")
            {
                let sort = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                col.sortDescriptorPrototype = sort
            }else if (col.identifier.rawValue == "fileSize")
            {
                let sort = NSSortDescriptor(key: sortbySizeKey, ascending: true)
                col.sortDescriptorPrototype = sort
            }else if (col.identifier.rawValue == "lastModifiedTime")
            {
                let sort = NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: true)
                col.sortDescriptorPrototype = sort
            }else if (col.identifier.rawValue == "driveAlias")
            {
                let sort = NSSortDescriptor(key: sortbyAliasKey, ascending: true)
                col.sortDescriptorPrototype = sort
            }
            
        }
        
        curSortDescriptor = [NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: false)]

        inited = true
    }
    
    public func refreshView(files: NSMutableArray, showEmptyImage: Bool = true){
        
        if isSharedWithMe {
            let lastModifyColumns = fileTableView.tableColumns.filter() { $0.identifier.rawValue == "lastModifiedTime" }
            if let lastModifyCol = lastModifyColumns.first {
                lastModifyCol.title = "Date Shared"
            }
            
            let sharedWithColumns = fileTableView.tableColumns.filter() { $0.identifier.rawValue == "sharedWith" }
            if let sharedWithCol = sharedWithColumns.first {
                sharedWithCol.title = "Shared By"
                // shared by sort
                let sort = NSSortDescriptor(key: sortbySharedBy, ascending: true)
                sharedWithCol.sortDescriptorPrototype = sort
            }
            
        } else {
            let lastModifyColumns = fileTableView.tableColumns.filter() { $0.identifier.rawValue == "lastModifiedTime" }
            if let lastModifyCol = lastModifyColumns.first {
                lastModifyCol.title = "Date Modified"
            }
            
            let sharedWithColumns = fileTableView.tableColumns.filter() { $0.identifier.rawValue == "sharedWith" }
            if let sharedWithCol = sharedWithColumns.first {
                sharedWithCol.title = "Shared With"
                // remove shared sort
                sharedWithCol.sortDescriptorPrototype = nil
            }
        }
        
        fileData = files
        
        if fileData.count == 0 && showEmptyImage {
            emptyView.isHidden = false
            emptyLabel.isHidden = false
            tableScrollView.isHidden = true
            
            backUpFileData = []
            currentSearchData = []
        }
        else {
            emptyView.isHidden = true
            emptyLabel.isHidden = true
            tableScrollView.isHidden = false
            if (curSortDescriptor != nil)
            {
                fileData.sort(using: curSortDescriptor!)
            }
            backUpFileData = fileData.copy() as! NSArray
            currentSearchData = fileData.copy() as! NSArray
            
            if isSharedWithMe == false, isFavorite == false {
                prepareWithType()
            }
            
            dataViewDelegate?.selectionChanged(files: [])
            fileTableView.reloadData()
        }
        
    }
    
    private func resetTableColumnWithType() {
        if currentType == .protectFile {
            fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sharedWith"))?.isHidden = true
        } else {
            fileTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sharedWith"))?.isHidden = false
        }
        
    }
    
    public func operationBarMenuItemSelected(tittle:String)
    {
        currentSelectedMenuTittle = tittle
        currentType = getMyVaultListType(with: tittle)
        prepareWithType()
        
        dataViewDelegate?.selectionChanged(files: [])
        
        if fileData.count == 0 {
            emptyLabel.isHidden = false
            emptyView.isHidden = false
            tableScrollView.isHidden = true
        }
        else {
            emptyLabel.isHidden = true
            emptyView.isHidden = true
            tableScrollView.isHidden = false
            fileTableView.reloadData()
        }
        
    }
    
    private func getMyVaultListType(with title: String?) -> MyVaultFileListType {
        var listType: MyVaultFileListType = .allFile
        if let title = title {
            switch title {
            case "All Files":
                listType = .allFile
                
            case "Shared Files":
                listType = .activeShare
                
            case "Protected Files":
                listType = .protectFile
               
            case "Deleted Files":
                listType = .deleted
                
            case "Revoked Files":
                listType = .revokedFiles
                
            default:
                break
            }

        }
        
        return listType
    }
    
    private func prepareWithType() {
        if backUpFileData.count == 0 {
            return
        }
        
        if currentType == .allType {
            currentType = getMyVaultListType(with: currentSelectedMenuTittle)
        }
        
        resetDisplayDataWithType()
        resetTableColumnWithType()
    }
    
    private func resetDisplayDataWithType() {
        
        let tempSearchData:NSMutableArray = NSMutableArray.init()
        
        switch currentType {
        case .allFile:
            fileData =  backUpFileData.mutableCopy() as! NSMutableArray
            currentSearchData = fileData.copy()as! NSArray
            
        case .allShare:
            for myVaultFile in backUpFileData {
                if (myVaultFile as! NXNXLFile).isShared == true {
                    tempSearchData.add(myVaultFile)
                }
            }
            
            fileData = tempSearchData
            currentSearchData = fileData.copy()as! NSArray
    
        case .activeShare:
            for file in backUpFileData {
                if let myVaultFile = file as? NXNXLFile {
                    if myVaultFile.isShared == true,
                        myVaultFile.isRevoked == false,
                        myVaultFile.isDeleted == false {
                        tempSearchData.add(myVaultFile)
                    }
                }
            }
            
            fileData = tempSearchData
            currentSearchData = fileData.copy()as! NSArray

        case .deleted:
            for myVaultFile in backUpFileData {
                if (myVaultFile as! NXNXLFile).isDeleted == true {
                    tempSearchData.add(myVaultFile)
                }
            }
            
            fileData = tempSearchData
            currentSearchData = fileData.copy()as! NSArray
            
        case .protectFile:
            for myVaultFile in backUpFileData {
                if (myVaultFile as! NXNXLFile).isShared == false{
                    tempSearchData.add(myVaultFile)
                }
            }
            
            fileData = tempSearchData
            currentSearchData = fileData.copy()as! NSArray
            
        case .revokedFiles:
            for myVaultFile in backUpFileData {
                if (myVaultFile as! NXNXLFile).isRevoked == true {
                    tempSearchData.add(myVaultFile)
                }
            }
            
            fileData = tempSearchData
            currentSearchData = fileData.copy()as! NSArray
        default:
            break
        }
    }
    
    public func updateData(searchString:String, showEmptyImage: Bool = true){
        var predicate:NSPredicate = NSPredicate()
        let tempSearchData:NSMutableArray = currentSearchData.mutableCopy() as! NSMutableArray
        searchStringForHightLight = searchString
        
        if searchString.isEmpty
        {
            self.fileData = currentSearchData.mutableCopy() as! NSMutableArray
        }
        else
        {
            predicate = NSPredicate(format: "name contains[cd] %@",searchString)
            tempSearchData.filter(using: predicate)
        }
        
        fileData = tempSearchData
        if fileData.count == 0 && showEmptyImage {
            emptyView.isHidden = false
            emptyLabel.isHidden = false
            tableScrollView.isHidden = true
        }
        else {
            emptyView.isHidden = true
            emptyLabel.isHidden = true
            tableScrollView.isHidden = false
            dataViewDelegate?.selectionChanged(files: [])
            fileTableView.reloadData()
        }
    }

    private func clearData(){
        fileData = NSMutableArray()
        
        dataViewDelegate?.selectionChanged(files: [])
        fileTableView.reloadData()
    }
    
    private func createIconFileNXFileBase(file: NXFileBase) ->NSImage
    {
        if ((file as? NXFolder) != nil){  // folder
            let img = NSImage(named: "folder_black")
            return img!
        } else{  // file
            var fileName = file.name
            fileName = fileName.lowercased()
            return NSImage(named:  NXCommonUtils.getFileTypeIcon(fileName: fileName))!
        }
        
    }
    
    // NSTableView Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileData.count
    }

    // this is for view-based
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        
        for column in fileTableView.tableColumns {
            if column.identifier.rawValue == "driveAlias" {
                column.isHidden = !isFavorite
            } else if column.identifier.rawValue == "sharedWith" {
                column.isHidden = isFavorite
            }
        }
        
        if let file = fileData.object(at: row) as? NXNXLFile {
            if ((tableColumn?.identifier)!.rawValue == "fileName") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCellView"), owner: self) as! NSTableCellView
                // show image
                let fileImg = cellView.viewWithTag(1) as! NSImageView
                if file.isDeleted! {
                    fileImg.image = NSImage(named: "file_deleted")
                }else{
                    fileImg.image = createIconFileNXFileBase(file: file)
                }
                
                
                // show file name
                let fileNameButton = cellView.viewWithTag(2) as! NSButton
                fileNameButton.identifier = NSUserInterfaceItemIdentifier(rawValue: String(row))
                
                fileNameButton.title = file.name
                
                let attributeStr = NSMutableAttributedString(attributedString: fileNameButton.attributedTitle)
                let range = NSMakeRange(0, file.name.count)
                if file.isDeleted == true {
                    attributeStr.addAttribute(NSAttributedString.Key.strikethroughStyle, value:1, range: range)
                    attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
                    fileNameButton.attributedTitle = attributeStr
                    
                } else if file.isRevoked == true {
                    attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value:NSColor.lightGray, range: range)
                    fileNameButton.attributedTitle = attributeStr
                    
                }
                
                // fav mark
                if let imageView = cellView.viewWithTag(3) as? NSImageView {
                    if file.isDeleted == true {
                        imageView.isHidden = true
                    } else {
                        if file.isFavorite == true {
                            imageView.isHidden = false
                        } else {
                            imageView.isHidden = true
                        }
                    }
                    
                }
                
                
                return cellView
                
            } else if ((tableColumn?.identifier)!.rawValue == "fileSize") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileSize"), owner: self) as! NSTableCellView
                cellView.textField?.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
                return cellView
            } else if ((tableColumn?.identifier)!.rawValue == "lastModifiedTime") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "lastModifiedTime"), owner: self) as! NSTableCellView
                cellView.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
                
                return cellView
            } else if ((tableColumn?.identifier)!.rawValue == "sharedWith") {
                let cellView = tableView.makeView(withIdentifier:NSUserInterfaceItemIdentifier(rawValue: "sharedWith"), owner:self) as! NXMyVaultFileTableShareWithCellView
                
                cellView.strArray.removeAll()
                if let sharedWith = file.sharedWith {
                    cellView.strArray = separateSharedWithToArray(sharedWith: sharedWith)
                }
                
                return cellView
            } else if ((tableColumn?.identifier)!.rawValue == "driveAlias") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "driveAlias"), owner: self) as! NSTableCellView
                cellView.imageView = nil
                cellView.textField?.stringValue = file.boundService?.serviceAlias ?? ""
                cellView.textField?.alignment = .left
                
                return cellView
            } else {
                return nil
            }
            
        } else if let file = fileData.object(at: row) as? NXSharedWithMeFile { // shared with me
            if (tableColumn?.identifier)!.rawValue == "fileName" {
                if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCellView"), owner: self) as? NSTableCellView,
                    let fileImg = cellView.viewWithTag(1) as? NSImageView,
                    let fileNameButton = cellView.viewWithTag(2) as? NSButton {
                    fileImg.image = createIconFileNXFileBase(file: file)
                    
                    fileNameButton.identifier = NSUserInterfaceItemIdentifier(rawValue: String(row))
                    fileNameButton.title = file.name
                    
                    // fav mark
                    if let imageView = cellView.viewWithTag(3) as? NSImageView {
                        imageView.isHidden = true
                    }
                    
                    return cellView
                }
                
            } else if (tableColumn?.identifier)!.rawValue == "fileSize" {
                if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileSize"), owner: self) as? NSTableCellView {
                    cellView.textField?.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
                    return cellView
                }
                
            } else if ((tableColumn?.identifier)!.rawValue == "lastModifiedTime") {
                if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "lastModifiedTime"), owner: self) as? NSTableCellView {
                    cellView.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
                    return cellView
                }
                
            } else if ((tableColumn?.identifier)!.rawValue == "sharedWith") {
                if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sharedBy"), owner: self) as? NSTableCellView {
                    cellView.textField?.stringValue = file.sharedBy ?? ""
                    return cellView
                }
            }
        } else if let file = fileData.object(at: row) as? NXFileBase {
            if ((tableColumn?.identifier)!.rawValue == "fileName")
            {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCellView"), owner: self) as! NSTableCellView
                // show image
                let fileImg = cellView.viewWithTag(1) as! NSImageView
                fileImg.image = createIconFileNXFileBase(file: file)
                
                // show file name
                let fileNameButton = cellView.viewWithTag(2) as! NSButton
                fileNameButton.identifier = NSUserInterfaceItemIdentifier(rawValue: String(row))
                
                fileNameButton.title = file.name
                
                // show fav, offline
                if let imageView = cellView.viewWithTag(3) as? NSImageView {
                    if file.isFavorite == true {
                        imageView.isHidden = false
                    } else {
                        imageView.isHidden = true
                    }
                }
                
                return cellView
                
            } else if ((tableColumn?.identifier)!.rawValue == "fileSize") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileSize"), owner: self) as! NSTableCellView
                cellView.textField?.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
                return cellView
                
            } else if ((tableColumn?.identifier)!.rawValue == "lastModifiedTime") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "lastModifiedTime"), owner: self) as! NSTableCellView
                
                cellView.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
                return cellView
            } else if ((tableColumn?.identifier)!.rawValue == "driveAlias") {
                let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "driveAlias"), owner: self) as! NSTableCellView
                cellView.imageView = nil
                cellView.textField?.stringValue = file.boundService?.serviceAlias ?? ""
                cellView.textField?.alignment = .left
                
                return cellView
            }

        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let myCustomView = HoverTableRowView()
        myCustomView.rowIndex = row
        myCustomView.rowDelegate = self
        return myCustomView
    }
    
    // selection changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let myTable = notification.object as? NSTableView {
            // we create an [Int] array from the index set
            let selected = myTable.selectedRowIndexes.map { Int($0) }
            
            Swift.print("multiple selected \(selected)")
            
            var selectedItems:[NXFileBase] = []
            
            for item in selected{
                let curSelectedItem = fileData.object(at: item) as! NXFileBase
                selectedItems.append(curSelectedItem)
            }
            
            dataViewDelegate?.selectionChanged(files: selectedItems)
        }
    }
    
    public func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]){
        Swift.print("sort: \(tableView.sortDescriptors)")
        
        curSortDescriptor = tableView.sortDescriptors
        fileData.sort(using: curSortDescriptor!)
        
        dataViewDelegate?.selectionChanged(files: [])
        fileTableView.reloadData()
    }
    
    private func separateSharedWithToArray(sharedWith str: String) -> [String] {
        var returnArr = [String]()
        
        let andRange = str.range(of: " and ")
        if let range = andRange {
            let emailStr = String(str[..<range.lowerBound])
            let emails = emailStr.components(separatedBy: ", ")
            returnArr.append(contentsOf: emails)
            
            let othersStr = String(str[range.upperBound...])
            let spaceIndex = othersStr.firstIndex(of: " ")!
            let numberStr = String(othersStr[..<spaceIndex])
            returnArr.append(numberStr)
            
        } else {
            if !str.isEmpty {
                let emails = str.components(separatedBy: ", ")
                returnArr.append(contentsOf: emails)
            }
            
        }
        
        return returnArr
    }
    
    override func rightMouseDown(with event: NSEvent) {
        let mousePoint = convert(event.locationInWindow, from: nil)
        let mouseInTable = convert(mousePoint, to: fileTableView)
        let mouseRow = fileTableView.row(at: mouseInTable)
        
        if mouseRow == -1 {
            return
        }
        
        rightclickMenu = NXTableRightClickContextMenu(title: "")
        let file = fileData.object(at: mouseRow) as! NXFileBase
        rightclickMenu?.fileItem = file
        rightclickMenu?.operationDelegate = self
        rightclickMenu?.popUp(positioning: rightclickMenu?.item(at: 0), at: mousePoint, in: self)
    }
    
}

extension NXMyVaultFileTableView:HoverTableRowDelegate{
    
    func HoverTableRowEnter(row: Int) {
        let rowView = fileTableView.rowView(atRow: row, makeIfNecessary: false)
        let cellView = rowView?.view(atColumn: 0) as! NSTableCellView
        
        let file = fileData.object(at: row) as? NXFileBase
        
        fileMenu?.frame = NSRect(x: cellView.frame.size.width - (fileMenu.frame.size.width), y: 0, width: (fileMenu.frame.size.width), height: (fileMenu.frame.size.height))
        fileMenu.fileItem = file
        cellView.addSubview(fileMenu)
        
        curHoverFile = file
        
        if (hoverRow != -1){
            let tmp = fileTableView.rowView(atRow: hoverRow, makeIfNecessary: false) as? HoverTableRowView
            tmp?.mouseInside = false
        }
        hoverRow = row
    }
    
    func HoverTableRowExit(row: Int) {
        fileMenu?.removeFromSuperview()
        
        curHoverFile = nil
        hoverRow = -1
    }
}

extension NXMyVaultFileTableView: NXFileOperationDelegate{
    func nxFileOperation(type: NXFileOperation) {
        fileTableView.selectRowIndexes([hoverRow], byExtendingSelection: false)
        dataViewDelegate?.fileOperation(type: type, file: curHoverFile)
    }
}
