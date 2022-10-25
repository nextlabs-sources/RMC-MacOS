//
//  NXFileGridView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXFileGridView: NSView, NSCollectionViewDataSource, NSCollectionViewDelegate, NXCollectionItemDelegate, NXClipDelegate {

    
    @IBOutlet weak var fileCollectionView: NSCollectionView!
    @IBOutlet weak var clipView: NXClipView!
    private var fileData = NSMutableArray()
    private var currentSelectedArray = NSMutableArray()
    private var contextMenuView: NXContextMenuView?
    private var currentMoreClickedItem: Int = -1
    var dataViewDelegate: NXDataViewDelegate? = nil
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        configureCollectionView()
        clipView.clipDelegate = self
        // Drawing code here.
    }
    override func awakeFromNib() {
        contextMenuView = NXCommonUtils.createViewFromXib(xibName: "NXContextMenuView", identifier: "contextMenuView", frame: NSMakeRect(0, 0, 300, 180), superView: fileCollectionView) as? NXContextMenuView
        if contextMenuView == nil {
            Swift.print("fail to show context menu")
        }
        else {
            contextMenuView?.isHidden = true
        }
    }
    
    public func refreshData(files: NSMutableArray){
        fileData = files
        fileCollectionView.reloadData()
    }
    //Mark: private method
    private func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 300.0, height: 180)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        fileCollectionView.collectionViewLayout = flowLayout
        // 2
        fileCollectionView.layer?.backgroundColor = BK_COLOR.cgColor
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
    private func clearData(){
        fileData.removeAllObjects()
        fileCollectionView.reloadData()
        currentSelectedArray.removeAllObjects()
    }
    private func sortByLastModifiedDate(){
        fileData.sort(comparator: {return ($0 as! NXFileBase).lastModifiedDate.compare(($1 as! NXFileBase).lastModifiedDate as Date)})
    }
    private func sortByA2Z(){
        fileData.sort(comparator: {return ($0 as! NXFileBase).name.compare(($1 as! NXFileBase).name)})
    }
    private func sortByZ2A(){
        fileData.sort(comparator: {return ($0 as! NXFileBase).name.compare(($1 as! NXFileBase).name) == .orderedAscending ? .orderedAscending : .orderedAscending})
    }
    //Mark: NSCollectionViewDataSource
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return fileData.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXCollectionItem"), for: indexPath)
        guard let collectionItem = item as? NXCollectionItem else {
            return item
        }
        let file = fileData.object(at: indexPath.item) as! NXFileBase
        
        if file is NXFile {
            var sizeStr: String!
            if file.size / 1024 == 0 {
                sizeStr = "\(file.size) B"
            }
            else if file.size / 1024 / 1024 == 0 {
                sizeStr = String(format: "%.2f", Float(file.size) / 1024)
                sizeStr.append(" KB")
            }
            else {
                sizeStr = String(format: "%.2f", Float(file.size) / 1024 / 1024)
                sizeStr.append(" MB")
            }
            collectionItem.infoLabel.stringValue = "\(file.name)\r\n\(sizeStr!)"
            collectionItem.thumbnailBtn.image = NSImage(named:"file_gray")
        }
        else {
            collectionItem.infoLabel.stringValue = "\(file.name)"
            collectionItem.thumbnailBtn.image = NSImage(named: "folder_gray")
        }
        //TODO: load image
        collectionItem.typeImage.image = createIconFileNXFileBase(file: file)
        
        collectionItem.id = indexPath.item
        collectionItem.delegate = self
        collectionItem.setHighlight(selected: false)
        if currentMoreClickedItem == indexPath.item {
            collectionItem.showOverlay(show: true)
        }
        return collectionItem
    }
    //Mark: NSCollectionViewDelegate
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        var selectedItems:[NXFileBase] = []
        let selectedArray = indexPaths.map { Int($0.item) }
        for selected in selectedArray {
            guard let item = collectionView.item(at: selected) else {return}
            (item as! NXCollectionItem).setHighlight(selected: true)
            currentSelectedArray.add(selected)
        }
        for currentSelected in currentSelectedArray {
            let curSelectedItem = fileData.object(at: currentSelected as! Int) as! NXFileBase
            selectedItems.append(curSelectedItem)
            Swift.print("selected \(currentSelected)")
        }
        dataViewDelegate?.selectionChanged(files: selectedItems)
    }
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        
        let deselectedArray = indexPaths.map { Int($0.item) }
        for deselected in deselectedArray {
            guard let item = collectionView.item(at: deselected) else {return}
            (item as! NXCollectionItem).setHighlight(selected: false)
            Swift.print("deselected \(deselected)")
            currentSelectedArray.remove(deselected)
        }
        
        
        var selectedItems:[NXFileBase] = []
        for currentSelected in currentSelectedArray {
            let curSelectedItem = fileData.object(at: currentSelected as! Int) as! NXFileBase
            selectedItems.append(curSelectedItem)
            Swift.print("selected \(currentSelected) left")
        }
        
        dataViewDelegate?.selectionChanged(files: selectedItems)
    }
    

    //MARK: NXCollectionItemDelegate
    func thumbnailImageClicked(id: Int){
        let file = fileData.object(at: id) as! NXFileBase
       
        if file is NXFolder {
            clearData()
            dataViewDelegate?.folderClicked(folder: file)
        }
        else {
            dataViewDelegate?.fileClicked(file: file)
        }
    }
    func moreBtnClicked(id: Int) {
        
        if let olditem = fileCollectionView.item(at: currentMoreClickedItem) as? NXCollectionItem {
            olditem.showOverlay(show: false)
        }
        if let newitem = fileCollectionView.item(at: id) as? NXCollectionItem  {
            contextMenuView?.frame = newitem.view.frame
            contextMenuView?.isHidden = false
            newitem.showOverlay(show: true)
        }
        currentMoreClickedItem = id
    }
    func collectionItemMouseDown() {
        if let olditem = fileCollectionView.item(at: currentMoreClickedItem) as? NXCollectionItem {
            olditem.showOverlay(show: false)
        }
        contextMenuView?.isHidden = true
        currentMoreClickedItem = -1
    }
    
    //NXClipDelegate
    func clicked() {
        if let olditem = fileCollectionView.item(at: currentMoreClickedItem) as? NXCollectionItem {
            olditem.showOverlay(show: false)
        }
        contextMenuView?.isHidden = true
        currentMoreClickedItem = -1
    }
    
}
