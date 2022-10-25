//
//  NXFileTableView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXFileTableView: NSView, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var emptyView: NSImageView!
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var tableScrollView: NSScrollView!
    
    var fileData = NSMutableArray()
    
    var backUpFileData = NSArray()
    var searchStringForHightLight:String?
    
    weak var dataViewDelegate: NXDataViewDelegate? = nil
    
    private var curSortDescriptor:[NSSortDescriptor]? = nil
    
    fileprivate var fileMenu : NXFileMenuView! = nil
    fileprivate var curHoverFile: NXFileBase? = nil
    fileprivate var rightclickMenu: NXTableRightClickContextMenu?
    
    private var inited = false
    
    fileprivate var hoverRow = -1
    
    var shouldHiddenSortByRepo:Bool = false
    
    fileprivate let sortbyNameKey = "name"
    fileprivate let sortbyLastModifiedTimeKey = "lastModifiedTime"
    fileprivate let sortbySizeKey = "size"
    fileprivate let sortbyAliasKey = "boundService.serviceAlias"
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
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
            dataViewDelegate?.fileClicked(file:curSelected)
        }
    }
    
    override func viewDidMoveToSuperview()
    {
        super.viewDidMoveToSuperview()
        searchStringForHightLight = ""
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
    func doWork(){
        if inited {
            return
        }
        
        let rect = NSRect(x: 0, y: 0, width: 200, height: 40)
        fileMenu = NXFileMenuView(frame: rect)
        fileMenu.delegate = self
        fileTableView.rowHeight = 40.0
        
        emptyView.isHidden = true
        emptyLabel.isHidden = true
        
        
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
        
        fileData = files
        
        if fileData.count == 0 && showEmptyImage {
            emptyLabel.isHidden = false
            emptyView.isHidden = false
            tableScrollView.isHidden = true
            backUpFileData = []
            
        }
        else {
            emptyLabel.isHidden = true
            emptyView.isHidden = true
            tableScrollView.isHidden = false
            if (curSortDescriptor != nil)
            {
                let temFileArray = NSMutableArray()
                let temFolderArray = NSMutableArray()
                let newSort = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                
                for item in fileData {
                    if  ((item as? NXFolder) != nil) {
                        temFolderArray.add(item)
                    }
                    else
                    {
                        temFileArray.add(item)
                    }
                }
                
                temFolderArray.sort(using: [newSort])
                temFileArray.sort(using: curSortDescriptor!)
                
                fileData.removeAllObjects()
                
                for item in temFolderArray {
                    fileData.add(item)
                }
                
                for item in temFileArray {
                    fileData.add(item)
                }
            }
            
            searchStringForHightLight = ""
            backUpFileData = fileData.copy() as! NSArray
            
            dataViewDelegate?.selectionChanged(files: [])
            fileTableView.reloadData()

        }
        
    }
    
    public func updateData(searchString:String, showEmptyImage: Bool = true){
        var predicate:NSPredicate = NSPredicate()
        let tempSearchData:NSMutableArray = backUpFileData.mutableCopy() as! NSMutableArray
        
        if searchString.isEmpty
        {
             searchStringForHightLight = ""
             self.fileData = backUpFileData.mutableCopy() as! NSMutableArray
        }
        else
        {
            searchStringForHightLight = searchString
            predicate = NSPredicate(format: "name contains[cd] %@",searchString)
            tempSearchData.filter(using: predicate)
        }
        
        fileData = tempSearchData
        if fileData.count == 0 && showEmptyImage{
            emptyLabel.isHidden = false
            emptyView.isHidden = false
            tableScrollView.isHidden = true
        }
        else {
            emptyLabel.isHidden = true
            emptyView.isHidden = true
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
        let file = fileData.object(at: row) as! NXFileBase
        for item in tableView.tableColumns {
            if shouldHiddenSortByRepo == true && item.identifier.rawValue == "driveAlias" {
                 item.isHidden = true
            }
            else
            {
                item.isHidden = false
            }
        }
        
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
            if let imageView = cellView.viewWithTag(4) as? NSImageView {
                if file.isOffline == true {
                    imageView.isHidden = false
                } else {
                    imageView.isHidden = true
                }
            }
            
            return cellView
            
        }else if ((tableColumn?.identifier)!.rawValue == "fileSize")
        {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileSize"), owner: self) as! NSTableCellView
            
            if (file as? NXFolder) != nil
            {
                cellView.textField?.stringValue = "-"
            }else{
                cellView.textField?.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
            }
            
            return cellView
        }else if ((tableColumn?.identifier)!.rawValue == "lastModifiedTime")
        {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "lastModifiedTime"), owner: self) as! NSTableCellView
            
            cellView.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
            return cellView
        }
        else if ((tableColumn?.identifier)!.rawValue == "driveAlias")
        {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "driveAlias"), owner: self) as! NSTableCellView
            cellView.imageView = nil
            cellView.textField?.stringValue = file.boundService?.serviceAlias ?? ""
            cellView.textField?.alignment = .left
           
            return cellView
        }
            
        else{
            return nil
        }
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
        
        if curSortDescriptor?.first?.key != sortbyAliasKey{
            let temFileArray = NSMutableArray()
            let temFolderArray = NSMutableArray()
            
            for item in fileData {
                if  ((item as? NXFolder) != nil) {
                    temFolderArray.add(item)
                }
                else
                {
                    temFileArray.add(item)
                }
            }
            
            if curSortDescriptor?.first?.key != sortbyNameKey {
                 temFolderArray.sort(using: curSortDescriptor!)
            }
            else
            {
                 let newSort = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                temFolderArray.sort(using: [newSort])
            }
            
            temFileArray.sort(using: curSortDescriptor!)
            
            fileData.removeAllObjects()
            
            for item in temFolderArray {
                fileData.add(item)
            }
            
            for item in temFileArray {
                fileData.add(item)
            }
        }
        // sortbyAliasKey
        else {
            fileData.sort(using: curSortDescriptor!)
            let files = fileData as NSArray as! [NXFileBase]
            
            var groups = [[NXFileBase]]()
            
            guard let firstFile = files.first else {
                return
            }
            
            var lastGroup = [NXFileBase]()
            var lastBS = firstFile.boundService
            
            for file in files {
                if file.boundService?.repoId == lastBS?.repoId,
                    file.boundService?.serviceType == lastBS?.serviceType { // boundservice is the same
                    lastGroup.append(file)
                } else {
                    groups.append(lastGroup)
                    lastGroup = [NXFileBase]()
                    lastBS = file.boundService
                    lastGroup.append(file)
                    
                }
            }
            groups.append(lastGroup)
            
            for group in groups {
                let temFileArray = NSMutableArray()
                let temFolderArray = NSMutableArray()
                for file in group {
                    if file is NXFolder {
                        temFolderArray.add(file)
                    } else {
                        temFileArray.add(file)
                    }
                }
                
                let sortByName = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                temFolderArray.sort(using: [sortByName])
                temFileArray.sort(using: [sortByName])
            }
            
            let fileList = groups.flatMap { return $0 }
            fileData = NSMutableArray(array: fileList)
        }
        
        dataViewDelegate?.selectionChanged(files: [])
        fileTableView.reloadData()
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

extension NXFileTableView:HoverTableRowDelegate{
    
    func HoverTableRowEnter(row: Int) {
        let rowView = fileTableView.rowView(atRow: row, makeIfNecessary: false)
        let cellView = rowView?.view(atColumn: 0) as! NSTableCellView
        
        fileMenu?.frame = NSRect(x: cellView.frame.size.width - (fileMenu.frame.size.width), y: 0, width: (fileMenu.frame.size.width), height: (fileMenu.frame.size.height))
        
        cellView.addSubview(fileMenu)
        let file = fileData.object(at: row) as! NXFileBase
        fileMenu.fileItem = file
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

extension NXFileTableView: NXFileOperationDelegate{
    func nxFileOperation(type: NXFileOperation) {
        fileTableView.selectRowIndexes([hoverRow], byExtendingSelection: false)
        dataViewDelegate?.fileOperation(type: type, file: curHoverFile)
        
    }
}
