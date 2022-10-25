//
//  NXRepoNavView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/6.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXRepoNavView: NSView {

    @IBOutlet weak var navOutlineView: NSOutlineView!
    
    var repoMenu = [NXMenuItem]()
    
    weak var repoNavDelegate: NXRepoNavDelegate? = nil
    
    let rowHeight:CGFloat = 32
    let imgSize:CGFloat = 20
    
    private var inited = false
    
    // FIXME: curSelection may incorrect when collapse, remove it in future
    
    fileprivate var previousSelection = (false, -1)
    fileprivate var isCollapse = false
    
    fileprivate var isSelectFromOutside = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToSuperview(){
        super.viewDidMoveToSuperview()
    }
    func selectItem(type: RepoNavItem, alias: String) {
        let foundAndSelectItem = {(menu: NXMenuItem) -> Bool in
            if type == menu.itemType,
                alias == menu.menuTitle {
                self.selectItem(item: menu)
                return true
            }
            return false
        }
        for item in repoMenu {
            if foundAndSelectItem(item) == true {
                return
            }
            for subItem in item.subItems {
                if foundAndSelectItem(subItem) == true {
                    return
                }
            }
        }
    }
    func updateUI(allBoundServices: [(boundService:NXBoundService, root: NXFileBase)]) {
        
        createMenu(allBoundServices: allBoundServices)
        
        navOutlineView.reloadData()
        
    }
    func doWork(allBoundServices: [(boundService:NXBoundService, root: NXFileBase)]){  // should be invoked by caller
        if inited {
            return
        }
        
        navOutlineView.delegate = self
        navOutlineView.rowHeight = rowHeight
        
        createMenu(allBoundServices: allBoundServices)
     
        navOutlineView.reloadData()
        navOutlineView.expandItem(nil, expandChildren: true)
        
        inited = true
    }
    
    private func createMenu(allBoundServices: [(boundService:NXBoundService, root: NXFileBase)]){
        let separator = NXMenuItem()
        separator.itemType = .separator
        
        repoMenu.removeAll()
        

        // my vault
        let myvault = NXMenuItem()
        myvault.itemType = .myVault
        myvault.menuTitle = NSLocalizedString("STRING_MYVAULT", comment: "")
        myvault.iconNameSelected = "myvault"
        myvault.iconNameUnselected = "myvault_grey"
        
        repoMenu.append(myvault)
        
        // my drive
        for bs in allBoundServices {
            if bs.boundService.serviceType == ServiceType.kServiceSkyDrmBox.rawValue{
                let tmp = NXMenuItem()
                tmp.menuTitle = NSLocalizedString("STRING_MYDRIVE", comment: "")
                tmp.iconNameSelected = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: bs.boundService.serviceType)
                tmp.iconNameUnselected = NXCommonUtils.getCloudDriveIconForUnselected(cloudDriveType: bs.boundService.serviceType)
                tmp.userData = bs
                tmp.itemType = .myDrive
                
                repoMenu.append(tmp)
                
                break
            }
            
        }
        
        // separator
        repoMenu.append(separator)
        
        // all files menu
        let allFiles = NXMenuItem()
        allFiles.menuTitle = NSLocalizedString("REPO_STRING_ALLFILES", comment: "")
        allFiles.itemType = .allFiles
        allFiles.iconNameSelected = "allfiles"
        allFiles.iconNameUnselected = "allfiles_grey"
        // sub items
        for bs in allBoundServices {
                let tmp = NXMenuItem()
                tmp.menuTitle = bs.boundService.serviceAlias
                tmp.iconNameSelected = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: bs.boundService.serviceType)
                tmp.iconNameUnselected = NXCommonUtils.getCloudDriveIconForUnselected(cloudDriveType: bs.boundService.serviceType)
                tmp.userData = bs
                tmp.itemType = .cloudDrive
                
                allFiles.subItems.append(tmp)
        }
        
        repoMenu.append(allFiles)
        
        // favorite 
        let favorite = NXMenuItem()
        favorite.itemType = .favoriteFiles
        favorite.menuTitle = NSLocalizedString("REPO_STRING_FAVORITEFILES", comment: "")
        favorite.iconNameSelected = "favoritemenu"
        favorite.iconNameUnselected = "favoritemenu_grey"
        
        repoMenu.append(favorite)
        
        // Deleted files
        let deleted = NXMenuItem()
        deleted.itemType = .deleted
        deleted.menuTitle = NSLocalizedString("REPO_STRING_DELETEDFILES", comment: "")
        // FIXME: use deleted icon
        deleted.iconNameSelected = "Deleted files - black"
        deleted.iconNameUnselected = "Deleted files - gray"
        
        repoMenu.append(deleted)
        
        // Shared Files
        let shared = NXMenuItem()
        shared.itemType = .shared
        shared.menuTitle = NSLocalizedString("REPO_STRING_SHAREDFILES", comment: "")
        // FIXME: use shared icon
        shared.iconNameSelected = "Shared files - black"
        shared.iconNameUnselected = "Shared files - gray"
        
        repoMenu.append(shared)
    }
    
    private func expendParent(item: Any?) {
        // FIXME: parent(forItem: tmp) return nil always
        // Just expand all
        navOutlineView.expandItem(nil, expandChildren: true)
    }
    
    func selectItem(item: Any?) {
        var index = navOutlineView.row(forItem: item)
        if index < 0 {
            expendParent(item: item)
            index = navOutlineView.row(forItem: item)
            if index < 0 {
                return
            }
        }
        
        isSelectFromOutside = true
        
        navOutlineView.selectRowIndexes([index], byExtendingSelection: false)
    }
    
    func getItemIndex(item: Any?) -> Int? {
        var index = navOutlineView.row(forItem: item)
        if index < 0 {
            expendParent(item: item)
            index = navOutlineView.row(forItem: item)
            if index < 0 {
                return nil
            }
        }
        
        return index
    }
    
    func isItemSelected(item: Any?) -> Bool {
        let index = getItemIndex(item: item)
        let currentSelection = getCurrentSelection(from: previousSelection)
        if index == currentSelection.1 {
            return true
        }

        return false
    }
    
    func getMenuItem(with navName: String, navType: RepoNavItem) -> NXMenuItem? {
        for item in repoMenu {
            if item.menuTitle == navName,
                item.itemType == navType {
                return item
            }
            for subItem in item.subItems {
                if subItem.menuTitle == navName,
                    subItem.itemType == navType {
                    return subItem
                }
            }
        }
        
        return nil
    }
    
    // Update data in menu
    func updateMenuItem(with bs: NXBoundService) {
        for item in repoMenu {
            if let service = item.userData as? (boundService:NXBoundService, root: NXFileBase),
                service.boundService.repoId == bs.repoId { // judge bound service equal
                item.userData = (bs, service.root)
                return
            }
            for subItem in item.subItems {
                if let service = subItem.userData as? (boundService:NXBoundService, root: NXFileBase),
                    service.boundService.repoId == bs.repoId { // judge bound service equal
                    subItem.userData = (bs, service.root)
                    return
                }
            }
        }
        
    }
    
    // FIXME: not a good way just for judging reselect the same row when use empty outline
    // only support allfiles collapse
    fileprivate func getCurrentSelection(from previousSelection: (Bool, Int)) -> (Bool, Int) {
        
        if previousSelection.0 == isCollapse {
            return previousSelection
        }
        
        var allFileIndex: Int?
        for (index, repo) in repoMenu.enumerated() {
            if repo.itemType == .allFiles {
                allFileIndex = index
            }
        }
        guard let collapseIndex = allFileIndex else {
            return (isCollapse, previousSelection.1)
        }
        
        if previousSelection.1 <= collapseIndex {
            return (isCollapse, previousSelection.1)
        }
        
        var currentSelectionIndex = 0
        if previousSelection.0 == false {
            currentSelectionIndex = previousSelection.1 - repoMenu[collapseIndex].subItems.count
        } else {
            currentSelectionIndex = previousSelection.1 + repoMenu[collapseIndex].subItems.count
        }
        
        return (isCollapse, currentSelectionIndex)
    }
}

extension NXRepoNavView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return repoMenu.count
        }else{
            let tmp = item as? NXMenuItem
            return (tmp?.subItems.count)!
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil{
            return repoMenu[index]
        }else{
            let tmp = item as? NXMenuItem
            return tmp?.subItems[index] as Any
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let tmp = item as? NXMenuItem
        return (tmp?.subItems.count)! > 0
        
    }

}

extension NXRepoNavView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        // More code here
        
        if let tmp = item as? NXMenuItem{
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "menuItemCell"), owner: self) as? NSTableCellView
            
            var sepView:NSView? = nil
            for separator in (view?.subviews)!{
                if separator.identifier!.rawValue == "separator"{
                    sepView = separator
                    break
                }
            }
            
            let Img = view?.viewWithTag(1) as! NSImageView
            let label = view?.viewWithTag(2) as! NSTextField
            
            if tmp.itemType == .separator{
                sepView?.isHidden = false
                Img.isHidden = true
                label.isHidden = true
            }else{
                sepView?.isHidden = true
                Img.isHidden = false
                label.isHidden = false
            }
            
            if tmp.iconNameUnselected == nil{
                label.frame = NSRect(x: 0, y: label.frame.origin.y, width: label.frame.size.width, height: label.frame.size.height)
            }else{
                Img.image = NSImage(named:  tmp.iconNameUnselected!)
                
                
                label.frame = NSRect(x: imgSize + 8, y: label.frame.origin.y, width: label.frame.size.width, height: label.frame.size.height)
            }
            
            
            label.stringValue = tmp.menuTitle
            if isLabelTruncated(label: label) {
                label.toolTip = label.stringValue
            }
            else {
                label.toolTip = ""
            }
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        //1
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }
        //2
        let selectedIndex = outlineView.selectedRow
        
        // FIXME: prevent empty selection, change selection type is not a good solution
        if selectedIndex == -1 {
            let currentSelection = getCurrentSelection(from: previousSelection)
            outlineView.selectRowIndexes([currentSelection.1], byExtendingSelection: false)
            return
        }
        
        let currentSelection = getCurrentSelection(from: previousSelection)
        if selectedIndex == currentSelection.1 {
            if isSelectFromOutside {
                isSelectFromOutside = false
            } else {
                return
            }
        }

        previousSelection = (isCollapse, selectedIndex)
        
        let item = outlineView.item(atRow: selectedIndex) as? NXMenuItem
        
        Swift.print("clicked repo nav item, index: \(selectedIndex), item title: \(String(describing: item?.menuTitle))")
        
        
        repoNavDelegate?.navClicked(item: (item?.itemType)!, userData: item?.userData)
    }
    
    // use our own row, since we need to change selected row background
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        let myCustomView = NXRepoTableRow()
        myCustomView.delegate = self
        return myCustomView
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool{
        Swift.print("should select item, current selected \(navOutlineView.selectedRow)")
        let tmp = item as? NXMenuItem
        if tmp != nil && tmp?.itemType != .separator{
            return true
        }
        // we don't need to let select Separator
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int){
        Swift.print("added row: \(row), selected index: \(outlineView.selectedRow)")
    }
    func outlineViewItemWillCollapse(_ notification: Notification) {
        debugPrint("\(navOutlineView.selectedRow)")
    }
    
    func outlineViewItemDidCollapse(_ notification: Notification) {
        if navOutlineView.selectedRow == -1,
            let object = notification.userInfo?["NSObject"] {
            let row = navOutlineView.row(forItem: object)
            navOutlineView.selectRowIndexes([row], byExtendingSelection: false)
            debugPrint("\(object)")
            debugPrint("\(navOutlineView.selectedRow)")
        }
        
        isCollapse = true
    }
    
    func outlineViewItemDidExpand(_ notification: Notification) {
        isCollapse = false
    }
    
    private func isLabelTruncated(label: NSTextField) -> Bool {
        guard let cell = label.cell else {
            return false
        }
        let expansion = cell.expansionFrame(withFrame: label.frame, in: label)
        return !NSEqualRects(NSZeroRect, expansion)
    }
}

extension NXRepoNavView: NXRepoTableRowDelegate {
    func drawSelection(with rowView: NXRepoTableRow) {
        let row = navOutlineView.row(for: rowView)
        let item = navOutlineView.item(atRow: row) as? NXMenuItem
        
        let cellView = rowView.view(atColumn: 0) as! NSTableCellView
        let img = cellView.viewWithTag(1) as! NSImageView
        let label = cellView.viewWithTag(2) as! NSTextField
        
        label.textColor = NSColor(red: 57.0 / 255, green: 150.0 / 255, blue: 73.0 / 255, alpha: 1)
        if let selectImage = item?.iconNameSelected {
            img.image = NSImage(named:selectImage)
        }
        
    }
    
    func drawUnSelection(with rowView: NXRepoTableRow) {
        let row = navOutlineView.row(for: rowView)
        let item = navOutlineView.item(atRow: row) as? NXMenuItem
        
        let cellView = rowView.view(atColumn: 0) as! NSTableCellView
        let img = cellView.viewWithTag(1) as! NSImageView
        let label = cellView.viewWithTag(2) as! NSTextField
        
        label.textColor = NSColor.black
        if let unselectImage = item?.iconNameUnselected {
            img.image = NSImage(named:  unselectImage)
        }
    }
}
