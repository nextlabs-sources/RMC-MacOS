//
//  NXProjectTagTemplateView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/25.
//  Copyright © 2019 nextlabs. All rights reserved.
//


import Cocoa

class NXProjectTagTemplateView: NSView {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    
    var tagModel: NXProjectTagTemplateModel?
    var currentIndexPath: IndexPath?
    var indexPathSet: Set<IndexPath> = []
    var mandatorySection: [Int] = []

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToSuperview()
        
        if self.window == nil {
            return
        }
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        
        collectionView.register(NXProjectTagTemplateViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("ViewItemIndentifier"))
        collectionView?.register(NSNib.init(nibNamed: NSNib.Name.init("NXProjectTagCollectionHeaderView"), bundle: nil), forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier.init("ProjectTagCollectionHeadView"))
    }
    
    func getTags() -> [String: [String]]? {
        for int in mandatorySection {
            let newSet = indexPathSet.filter({($0.section == int)})
            if newSet.count == 0 {
                return nil
            }
        }
        
        var rootData = [String: [String]]()
        let pathArr = indexPathSet.sorted(by: { $0.item < $1.item })
        let sortArr = pathArr.sorted(by: { $0.section < $1.section })
        for indexPath in sortArr {
            let categoryModel = tagModel?.categories?[indexPath.section]
            let categoryName = categoryModel?.name ?? ""
            let labelModel = categoryModel?.labels?[indexPath.item]
            let labelName = labelModel?.name ?? ""
            if rootData.keys.contains(categoryName) {
                var newLabels = rootData[categoryName]
                newLabels?.append(labelName)
                rootData[categoryName] = newLabels
            }else{
                rootData[categoryName] = [labelName]
            }
        }
        
        return rootData
    }
    
}

extension NXProjectTagTemplateView: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return tagModel?.categories?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        let categoryModel = tagModel?.categories?[section]
        return categoryModel?.labels?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ViewItemIndentifier"), for: indexPath)
        guard let viewItem = item as? NXProjectTagTemplateViewItem else {
            return item
        }
        let categoryModel = tagModel?.categories?[indexPath.section]
        let labelModel = categoryModel?.labels?[indexPath.item]
        viewItem.nameLabel.stringValue = labelModel?.name ?? ""
        if labelModel?.isDefault == true {
            viewItem.isSelected = true
            indexPathSet.insert(indexPath)
        }
        if categoryModel?.mandatory == true && indexPath.item == 0 {
            mandatorySection.append(indexPath.section)
        }
        
        viewItem.indexPath = indexPath
        viewItem.delegate = self
        
        return viewItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let headView = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProjectTagCollectionHeadView"), for: indexPath) as? NXProjectTagCollectionHeaderView
        let categoryModel = tagModel?.categories?[indexPath.section]
        headView?.categoryNameLabel.stringValue = categoryModel?.name ?? ""
        if categoryModel?.mandatory == true {
            headView?.selectTypeLabel.stringValue = "(Mandatory)"
        }else {
            headView?.selectTypeLabel.stringValue = ""
        }

        if categoryModel?.mandatory == true {
            if let labels = categoryModel?.labels {
                for (index,_) in labels.enumerated() {
                    let item = collectionView.item(at: IndexPath(item: index, section: indexPath.section))
                    let labelModel = categoryModel?.labels?[indexPath.item]

                    if item?.isSelected == true || labelModel?.isDefault == true{
                        headView?.selectTypeLabel.textColor = RGB(r: 104, g: 116, b: 131)
                        return headView!
                    }
                }
                headView?.selectTypeLabel.textColor = NSColor.red
            }
        }

        return headView!
    }
}

extension NXProjectTagTemplateView: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: 180, height: 45)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let categoryModel = tagModel?.categories?[indexPath.section]
        let labelModel = categoryModel?.labels?[indexPath.item]
        let size = getStringSizeWithFont(string: labelModel?.name ?? "", font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 530, height: CGFloat.greatestFiniteMagnitude))
        return NSSize(width: size.width+35, height: 36)
    }
    
//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
//        return NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 0)
//    }
    
}

extension NXProjectTagTemplateView: NXProjectTagTemplateViewItemDelegate {
    func select(_ indexPath: IndexPath, _ item: NSCollectionViewItem) -> () {
        YMLog("section: \(indexPath.section), item: \(indexPath.item)")
        item.isSelected = !item.isSelected
        let categoryModel1 = self.tagModel?.categories?[indexPath.section]
        if self.indexPathSet.contains(indexPath) == true {
            self.indexPathSet.remove(indexPath)
        }else {
            if categoryModel1?.multiSelect == true {
                self.indexPathSet.insert(indexPath)
            }else if categoryModel1?.multiSelect == false {
                let newSet = self.indexPathSet.filter({($0.section == indexPath.section)})
                if newSet.count != 0 {
                    let preItem = self.collectionView.item(at: (newSet.first)!)
                    preItem?.isSelected = false
                    self.indexPathSet.remove((newSet.first)!)
                }
                self.indexPathSet.insert(indexPath)
            }
        }
        if categoryModel1?.mandatory == true {
            let newSet = self.indexPathSet.filter({($0.section == indexPath.section)})
            let headerIndexPath:IndexPath = IndexPath(item: 0, section: indexPath.section)
            
            let headView = collectionView.supplementaryView(forElementKind: NSCollectionView.elementKindSectionHeader, at: headerIndexPath) as? NXProjectTagCollectionHeaderView
            if newSet.count == 0 {
                headView?.selectTypeLabel.textColor = NSColor.red
            }else{
                headView?.selectTypeLabel.textColor = RGB(r: 104, g: 116, b: 131)
            }
        }
    }
    
}
