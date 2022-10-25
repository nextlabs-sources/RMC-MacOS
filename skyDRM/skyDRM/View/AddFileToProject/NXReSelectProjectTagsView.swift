//
//  NXReSelectProjectTagsView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/17.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

protocol NXReSelectProjectTagsViewDeletage: NSObjectProtocol {
    func changeProjectAction(syncFile: NXSyncFile?, projectModel: NXProjectModel?)
    func nextSelectTagsFinish(syncFile: NXSyncFile?, projectModel: NXProjectModel?, tags: [String: [String]], destinationStr: String)
}

class NXReSelectProjectTagsView: NSView {
    
    fileprivate struct Constant{
        static let standardInterval: CGFloat = 1
        static let collectionViewItemWidth: CGFloat = 480
        static let collectionViewTagsItemFixedHeight: CGFloat = 25
        static let collectionViewFileNameItemFixedHeight: CGFloat = 73
        static let collectionViewCaculateWidth: CGFloat = 480
        static let collectionViewExtraDistance: CGFloat = 10
        static let collectionViewFileNameItemExtraSpace: CGFloat = 40
    }
    
    @IBOutlet weak var backView: NSView!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var destinationLab: NSTextField!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var nextBtn: NSButton!
    
    @IBOutlet weak var changeDestinationButton: NXTrackingButton!
    @IBOutlet weak var tagDisplayCollectionView: NSCollectionView!
    var fileNameDisplay: String?
    var collectionViewDataSource = [String]()
    
    weak var delegate: NXReSelectProjectTagsViewDeletage?
    var currentIndexPath: IndexPath?
    var indexPathSet: Set<IndexPath> = []
    var mandatorySection: [Int] = []
    var tagModel: NXProjectTagTemplateModel? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var filePath: String? {
        didSet {
            if filePath != nil {
                fileNameDisplay = (filePath! as NSString).lastPathComponent
                tagDisplayCollectionView.reloadData()
            }
        }
    }
    var tags: [String: [String]]? {
        didSet {
            if tags != nil && tags?.count != 0 {
                collectionViewDataSource.removeAll()
                let tagDisplay  =  getTagsDisplayString(tags: tags!)
                for str in tagDisplay{
                    collectionViewDataSource.append(str)
                }
                tagDisplayCollectionView.reloadData()
            }
        }
    }
    
    var preFileModel: NXProjectFileModel? {
        didSet {
            if preFileModel != nil {
                   fileNameDisplay = preFileModel?.name ?? ""
                if (preFileModel?.tags != nil && preFileModel?.tags?.count != 0) {
                    collectionViewDataSource.removeAll()
                    let tagDisplay  =  getTagsDisplayString(tags: preFileModel!.tags!)
                    for str in tagDisplay{
                        collectionViewDataSource.append(str)
                    }
                    collectionView.reloadData()
                }
            }
        }
    }
    
    private func getTagsString(tags: [String: [String]]) -> (String, [String]) {
        var tagStr = ""
        var keysArr = [String]()
        for dict in tags {
            keysArr.append(dict.key)
            tagStr.append(dict.key)
            let sum = dict.value.count
            for (index,str) in dict.value.enumerated() {
                if sum == 1 {
                    tagStr = tagStr + "(" + str + ")"
                }else {
                    if index == sum - 1 {
                        tagStr = tagStr + str + ")"
                    }else if index == 0 {
                        tagStr = tagStr + "(" + str + ","
                    }else{
                        tagStr = tagStr + str + ","
                    }
                }
            }
            tagStr = tagStr + " "
        }
        return (tagStr,keysArr)
    }
    
    private func getTagsDisplayString(tags: [String: [String]]) -> ([String]) {
        var tagStr = ""
        var keysArr = [String]()
        var resultArr = [String]()
        if tags.keys.count == 0 {
            return [""]
        }
        for dict in tags {
            keysArr.append(dict.key)
            tagStr.append(dict.key)
            let sum = dict.value.count
            for (index,str) in dict.value.enumerated() {
                if sum == 1 {
                    tagStr = tagStr + ":" + "(" + str + ")"
                }else {
                    if index == sum - 1 {
                        tagStr = tagStr + str + ")"
                    }else if index == 0 {
                        tagStr = tagStr + ":" + "(" + str + ","
                    }else{
                        tagStr = tagStr + str + ","
                    }
                }
            }
            resultArr.append(tagStr)
            tagStr = ""
        }
        return resultArr
    }
    
    var destinationStr: String? {
        didSet {
            if destinationStr != nil {
                destinationLab.stringValue = destinationStr!
            }
        }
    }
    
    var projectModel: NXProjectModel?
    var syncFile: NXSyncFile?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.wantsLayer = true
        self.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        self.backView.wantsLayer = true
        self.backView.layer?.borderColor = RGB(r: 197, g: 197, b: 197).cgColor
        self.backView.layer?.borderWidth = 1
        
        nextBtn.wantsLayer = true
        nextBtn.layer?.cornerRadius = 5
        
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: nextBtn.bounds, start: startColor, end: endColor)
        nextBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: nextBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, nextBtn.title.count))
        nextBtn.attributedTitle = titleAttr
        
        let destinationdMuAtti = NSMutableAttributedString(attributedString: changeDestinationButton.attributedTitle)
        destinationdMuAtti.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: NSMakeRange(0, changeDestinationButton.title.count))
        changeDestinationButton.attributedTitle = destinationdMuAtti
        
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        
        collectionView.register(NXProjectTagTemplateViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("ViewItemIndentifier"))
        
        collectionView?.register(NSNib.init(nibNamed: NSNib.Name.init("NXProjectTagCollectionHeaderView"), bundle: nil), forSupplementaryViewOfKind:NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier.init("ProjectTagCollectionHeadView"))
        
        tagDisplayCollectionView.wantsLayer = true
        tagDisplayCollectionView.layer?.backgroundColor = NSColor.white.cgColor
        
        tagDisplayCollectionView.register(NXAddFileSelectNewProjectViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXAddFileSelectNewProjectViewItemIdentifier"))
        tagDisplayCollectionView.register(NXTagsDisplayViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXTagsDisplayViewItemIdentifier"))
        
        tagDisplayCollectionView.register(NSNib.init(nibNamed: NSNib.Name.init("NXProjectTagCollectionHeaderView"), bundle: nil), forSupplementaryViewOfKind:NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier.init("ProjectTagCollectionHeadView"))
        
        configureCollectionView()
//        destinationLab.wantsLayer = true
//        changeDestinationButton.wantsLayer = true
//        destinationLab.layer?.backgroundColor = NSColor.red.cgColor
//        changeDestinationButton.layer?.backgroundColor = NSColor.orange.cgColor
    }
    
    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 503, height: 30)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        tagDisplayCollectionView.collectionViewLayout = flowLayout
    }
    @IBAction func changeDesigationAction(_ sender: Any) {
        self.delegate?.changeProjectAction(syncFile: self.syncFile, projectModel: self.projectModel)
    }
    
    
    @IBAction func nextAction(_ sender: Any) {
        guard let tags = getTags() else {
            let message = "PROJECT_FILES_PROTECT_MANDATORY_NO".localized
            NSAlert.showAlert(withMessage: message)
            return
        }
        self.delegate?.nextSelectTagsFinish(syncFile: self.syncFile, projectModel: self.projectModel, tags: tags, destinationStr: destinationStr ?? "")
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    func getTags() -> [String: [String]]? {
        for int in mandatorySection {
            let newSet = indexPathSet.filter({($0.section == int)})
            if newSet.count == 0 {
                return nil
            }
        }
        
        var rootData = [String: [String]]()
        for indexPath in indexPathSet {
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
        
        if let preFileModel = preFileModel{
            return self.generateMergeTags(tags: preFileModel.tags!, rootTags: rootData)
        }
        
        if let tags = tags {
               return self.generateMergeTags(tags:tags, rootTags: rootData)
        }
        return rootData
    }
    
    func generateMergeTags(tags: [String: [String]],rootTags:[String: [String]]) -> [String: [String]] {
        
         var selectedTagIDSet = Set<String>()
         var currentProjectModelTagIDSet = Set<String>()
         var unselectedIDSet = Set<String>()
        
        let currentProjectModel_Enumerated_list = tagModel?.categories!.enumerated()
        for (_, projectTagCategoryModel) in  currentProjectModel_Enumerated_list! {
            currentProjectModelTagIDSet.insert(projectTagCategoryModel.name!)
        }
        
        for key in rootTags.keys {
            selectedTagIDSet.insert(key)
        }
        
        unselectedIDSet = currentProjectModelTagIDSet.subtracting(selectedTagIDSet)
        
        var needAddedTags = [String: [String]]()
        needAddedTags = tags
        for key in tags.keys {
            for unselectedKey in unselectedIDSet{
                if key.lowercased() == unselectedKey.lowercased() {
                    needAddedTags.removeValue(forKey: key)
                }
            }
        }
        
        var mergedTags = [String: [String]]()
        if needAddedTags.keys.count > 0 {
            for dict in needAddedTags {
                mergedTags[dict.key] = needAddedTags[dict.key]
            }
            
            for dict in rootTags {
                mergedTags[dict.key] = rootTags[dict.key]
            }
            return mergedTags
            
        }else{
            return rootTags
        }
    }
}

extension NXReSelectProjectTagsView: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        if collectionView == self.collectionView {
              return tagModel?.categories?.count ?? 0
        }else{
             return 2
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            let categoryModel = tagModel?.categories?[section]
            return categoryModel?.labels?.count ?? 0
        }else{
            if section == 0 {
                return 1
            }else{
                return collectionViewDataSource.count
            }
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        if collectionView == self.collectionView {
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
        }else{
            if indexPath.section == 0 {
                let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXAddFileSelectNewProjectViewItemIdentifier"), for: indexPath)
                guard let viewItem = item as? NXAddFileSelectNewProjectViewItem else {
                    return item
                }
                viewItem.setFileName(fileName: fileNameDisplay)
                
                return viewItem
            }else {
                
                let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXTagsDisplayViewItemIdentifier"), for: indexPath)
                guard let viewItem = item as? NXTagsDisplayViewItem else {
                    return item
                }
                let rightsDisplay = collectionViewDataSource[indexPath.item]
                viewItem.setRightsLabelDisplay(rightsTagDisplay:rightsDisplay)
                
                return viewItem
            }
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {

        if collectionView == self.collectionView {
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
        }else{
            let headView = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProjectTagCollectionHeadView"), for: indexPath) as? NXProjectTagCollectionHeaderView
            return headView!
        }
        
        
    }
}

extension NXReSelectProjectTagsView: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
         if collectionView == self.collectionView {
              return NSSize(width: 180, height: 45)
        }else{
              return NSSize(width: 503, height: 1)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
          if collectionView == self.collectionView {
            let categoryModel = tagModel?.categories?[indexPath.section]
            let labelModel = categoryModel?.labels?[indexPath.item]
            let size = getStringSizeWithFont(string: labelModel?.name ?? "", font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 520, height: CGFloat.greatestFiniteMagnitude))
            return NSSize(width: size.width+35, height: 36)
        }else{
            if indexPath.section == 0 {
                if let fileName = fileNameDisplay{
                    let size = getStringSizeWithFont(string: fileName, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: Constant.collectionViewCaculateWidth, height: CGFloat.greatestFiniteMagnitude))
                    if (size.height + Constant.collectionViewFileNameItemExtraSpace) < Constant.collectionViewFileNameItemFixedHeight{
                        return NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewFileNameItemFixedHeight)
                    }else{
                        return NSSize(width: Constant.collectionViewItemWidth,height: size.height + Constant.collectionViewExtraDistance + Constant.collectionViewFileNameItemExtraSpace)
                    }
                }else{
                    return NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewFileNameItemFixedHeight)
                }
            }else{
                
                let tagDisplay = collectionViewDataSource[indexPath.item]
                if tagDisplay.count > 0 {
                    let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width:Constant.collectionViewCaculateWidth, height: CGFloat.greatestFiniteMagnitude))
                    
                    if size.height < Constant.collectionViewTagsItemFixedHeight {
                        return  NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewTagsItemFixedHeight)
                    }else{
                        return  NSSize(width: Constant.collectionViewItemWidth,height: size.height + Constant.collectionViewExtraDistance)
                    }
                    
                }else{
                    return  NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewTagsItemFixedHeight)
                }
            }
        }
    }
    
    
//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
//        if collectionView == self.collectionView {
//              return NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
//        }else{
//             return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        }
//    }
}

extension NXReSelectProjectTagsView: NXProjectTagTemplateViewItemDelegate {
    func select(_ indexPath: IndexPath, _ item: NSCollectionViewItem) {
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
                    //                        let set1 = weakSelf?.indexPathSet.subtracting(Set(newSet!))
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
