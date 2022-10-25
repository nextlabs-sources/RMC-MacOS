//
//  NXProjectFileTableView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/1/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectFileTableView: NSView {

    @IBOutlet weak var fileTableView : NSTableView!
    @IBOutlet weak var emptyImage: NSImageView!
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet weak var tableScrollView: NSScrollView!
    
    fileprivate var fileData = NSMutableArray()
    var backUpFileData = NSArray()
    var searchStringForHightLight : String?
    weak var dataViewDelegate : NXDataViewDelegate? = nil
    
    fileprivate var curSortDescriptor:[NSSortDescriptor]? = nil
    
    fileprivate var fileMenu : NXFileMenuView! = nil
    fileprivate var curHoverFile: NXFileBase? = nil
    fileprivate var rightclickMenu: NXTableRightClickContextMenu?
    fileprivate var hoverRow = -1
    
    private var inited = false
    
    fileprivate let sortbyNameKey = "name"
    fileprivate let sortbyLastModifiedTimeKey = "lastModifiedTime"
    fileprivate let sortbySizeKey = "size"
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        var index = 0
        var width:CGFloat = 0
        
        var fileNameCol: NSTableColumn? = nil
        for col in fileTableView.tableColumns {
            if index != 0{
                width += col.width
            }else{
                fileNameCol = col
            }
            
            index += 1
        }
        
        fileNameCol?.width = dirtyRect.width - width - 40
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        searchStringForHightLight = ""
    }
    
    @IBAction func fileName(_ sender: NSButton) {
        let obj = sender 
        let index = Int((obj.identifier?.rawValue)!)
        Swift.print("clicked index: \(String(describing: index))")
        
        let curSelected = fileData.object(at: index!) as! NXFileBase
        
        
        if ((curSelected as? NXProjectFolder) != nil) {
            clearData()
            dataViewDelegate?.folderClicked(folder:curSelected)
            
        }else if ((curSelected as? NXProjectFile) != nil) {
            dataViewDelegate?.fileClicked(file:curSelected)
        }
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
    public func doWork() {
        if  inited {
            return
        }
        let rect = NSRect(x: 0, y: 0, width: 200, height: 40)
        fileMenu = NXFileMenuView(frame: rect)
        fileMenu.delegate = self
        fileTableView.rowHeight = 40.0
        
        emptyLabel.isHidden = true
        emptyImage.isHidden = true
        //handle sort
        // handle sort
        for col in fileTableView.tableColumns {
            if (col.identifier.rawValue == "fileName") {
                let sort = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                col.sortDescriptorPrototype = sort
            } else if (col.identifier.rawValue == "fileSize") {
                let sort = NSSortDescriptor(key: sortbySizeKey, ascending: true)
                col.sortDescriptorPrototype = sort
            }
            else if (col.identifier.rawValue == "sharedBy") {
                let sort = NSSortDescriptor(key: "owner.name", ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                col.sortDescriptorPrototype = sort
            }
            else if (col.identifier.rawValue == "lastModifiedTime") {
                let sort = NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: true)
                col.sortDescriptorPrototype = sort
            }
        }
        
        curSortDescriptor = [NSSortDescriptor(key: sortbyLastModifiedTimeKey, ascending: false)]
        
        inited = true
    }
    
    public func refreshView(files: NSMutableArray, showEmptyImage: Bool = true){
        fileData = files
        
        if fileData.count == 0 && showEmptyImage {
            emptyImage.isHidden = false
            emptyLabel.isHidden = false
            tableScrollView.isHidden = true
            backUpFileData = []
        }
        else {
            emptyLabel.isHidden = true
            emptyLabel.isHidden = true
            tableScrollView.isHidden = false
            if (curSortDescriptor != nil)
            {
                let temFileArray = NSMutableArray()
                let temFolderArray = NSMutableArray()
                let newSort = NSSortDescriptor(key: sortbyNameKey, ascending: true,selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                
                for item in fileData {
                    if  ((item as? NXProjectFolder) != nil) {
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
        
        if searchString.isEmpty {
            searchStringForHightLight = ""
            self.fileData = backUpFileData.mutableCopy() as! NSMutableArray
        } else {
            searchStringForHightLight = searchString
            predicate = NSPredicate(format: "name contains[cd] %@",searchString)
            tempSearchData.filter(using: predicate)
        }
        
        fileData = tempSearchData
        
        dataViewDelegate?.selectionChanged(files: [])
        
        if fileData.count == 0 && showEmptyImage {
            emptyImage.isHidden = false
            emptyLabel.isHidden = false
            tableScrollView.isHidden = true
        }
        else {
            emptyLabel.isHidden = true
            emptyLabel.isHidden = true
            tableScrollView.isHidden = false
            fileTableView.reloadData()
        }
    }
    
    private func clearData(){
        fileData = NSMutableArray()
        
        dataViewDelegate?.selectionChanged(files: [])
        fileTableView.reloadData()
    }
    
    fileprivate func createIconFileNXFileBase(file: NXFileBase) ->NSImage
    {
        if ((file as? NXProjectFolder) != nil){  // folder
            let img = NSImage(named:  "folder_black")
            return img!
        } else {
            var fileName = file.name
            fileName = fileName.lowercased()
            return NSImage(named:  NXCommonUtils.getFileTypeIcon(fileName: fileName))!
        }
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

extension NXProjectFileTableView : NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let file = fileData.object(at: row) as! NXFileBase
        
        var cellView : NSTableCellView?
        if (tableColumn?.identifier)!.rawValue == "fileName" {
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCellView"), owner: self) as? NSTableCellView
            if cellView?.subviews != nil {
                for item in (cellView?.subviews)! {
                    if ((item as? NXFileMenuView) != nil) {
                        item.removeFromSuperview()
                    }
                }
            }
            
            let fileImg = cellView?.viewWithTag(1) as! NSImageView
            let nameButton = cellView?.viewWithTag(2) as! NSButton
            // let timeLabel = cellView?.viewWithTag(3) as! NSTextField
            // let sizeLabel = cellView?.viewWithTag(4) as! NSTextField
            fileImg.image = createIconFileNXFileBase(file: file)
            nameButton.title = file.name
            nameButton.identifier = NSUserInterfaceItemIdentifier(rawValue: String(row))
            // timeLabel.stringValue = file.lastModifiedTime
            // sizeLabel.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
        } else if (tableColumn?.identifier)!.rawValue == "sharedBy" {
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SharedByCellView"), owner: self) as? NXProjectFileTableSharedByCell

            var ownerName = ""
            if file.isKind(of: NXProjectFile.self) {
               ownerName = ((file as! NXProjectFile).owner?.name)!;
            }
            if file.isKind(of: NXProjectFolder.self) {
                ownerName = ((file as! NXProjectFolder).owner?.name)!;
            }
            
            (cellView as! NXProjectFileTableSharedByCell).circleLabel?.text = NXCommonUtils.abbreviation(forUserName: ownerName)
            let index = (cellView as! NXProjectFileTableSharedByCell).circleLabel?.text.index((NXCommonUtils.abbreviation(forUserName: ownerName).startIndex), offsetBy: 1)
            if let colorHexValue = NXCommonUtils.circleViewBKColor[String(NXCommonUtils.abbreviation(forUserName: ownerName)[..<index!]).lowercased()]{
                (cellView as! NXProjectFileTableSharedByCell).circleLabel?.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
            }else{
                (cellView as! NXProjectFileTableSharedByCell).circleLabel?.backgroundColor = .red
            }
            
        } else if (tableColumn?.identifier)!.rawValue == "fileSize" {
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileSizeCellView"), owner: self) as? NSTableCellView
            if (file as? NXProjectFolder) != nil {
                cellView?.textField?.stringValue = "-"
            } else {
                cellView?.textField?.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
            }
        } else if  (tableColumn?.identifier)!.rawValue == "lastModifiedTime" {
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LastModifiedTimeCellView"), owner: self) as? NSTableCellView
            cellView?.textField?.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: file.lastModifiedDate as Date)
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let myCustomView = HoverTableRowView()
        myCustomView.rowIndex = row
        myCustomView.rowDelegate = self
        return myCustomView
    }
    
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
}

extension NXProjectFileTableView : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileData.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        Swift.print("sort: \(tableView.sortDescriptors)")
        curSortDescriptor = tableView.sortDescriptors
        
        let temFileArray = NSMutableArray()
        let temFolderArray = NSMutableArray()
        
        for item in fileData {
            if  ((item as? NXProjectFolder) != nil) {
                temFolderArray.add(item)
            }
            else
            {
                temFileArray.add(item)
            }
        }
        
        if curSortDescriptor?.first?.key != sortbySizeKey {
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
        
        dataViewDelegate?.selectionChanged(files: [])
        fileTableView.reloadData()
    }
}

extension NXProjectFileTableView : HoverTableRowDelegate {
    func HoverTableRowEnter(row: Int) {
        let rowView = fileTableView.rowView(atRow: row, makeIfNecessary: false)
        let cellView = rowView?.view(atColumn: 0) as! NSTableCellView
        
        let file = fileData.object(at: row) as! NXFileBase
        
        fileMenu?.frame = NSRect(x: cellView.frame.size.width - (fileMenu.frame.size.width), y: 0, width: (fileMenu.frame.size.width), height: (fileMenu.frame.size.height))
        cellView.addSubview(fileMenu)
        
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

extension NXProjectFileTableView: NXFileOperationDelegate{
    func nxFileOperation(type: NXFileOperation) {
        fileTableView.selectRowIndexes([hoverRow], byExtendingSelection: false)
        dataViewDelegate?.fileOperation(type: type, file: curHoverFile)
    }
}

