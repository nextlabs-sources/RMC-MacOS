//
//  NXTagsViewController.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/7.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXTagsViewController: NSViewController {
    struct Constant {
        static let tagsCollectionItemIdentifier = "NXResultTagsCollectionViewItemID"
        static let rightsCollectionViewItemIdentifier = "RightsViewItem"
        static let standardInterval: CGFloat = 8
        static let rightCountInRow = 6
    }
    
    @IBOutlet weak var tagsCollectionView: NSCollectionView!
    @IBOutlet weak var definedTypeLab: NSTextField!
    @IBOutlet weak var descLab: NSTextField!
    @IBOutlet weak var rightsDescLab: NSTextField!
    @IBOutlet weak var rightsCollection: NSCollectionView!
    @IBOutlet weak var watermarkText: NSTextField!
    @IBOutlet weak var validityText: NSTextField!
    @IBOutlet weak var watermarkLab: NSTextField!
    @IBOutlet weak var validityLab: NSTextField!
    @IBOutlet weak var accessDeniedView: NSView!
    @IBOutlet weak var accessDeniedLab: NSTextField!
    @IBOutlet weak var deniedDescLab: NSTextField!
    
    var type: FileInfoType?{
        didSet{
            if type == .noViewPolicy{
                rightsDescLab.isHidden = true
                rightsCollection.isHidden = true
                accessDeniedView.isHidden = false
                watermarkText.isHidden = true
                watermarkLab.isHidden  = true
                validityText.isHidden = true
                validityLab.isHidden = true
            }
        }
    }
    
    var right: NXRightObligation? {
        didSet {
            if let rights = self.right?.rights {
                self.rightTypes.append(contentsOf: rights)
            }
            var watermarkStr = ""
            if let watermark = self.right?.watermark {
                self.rightTypes.append(.watermark)
                watermarkStr = watermark.text
            }
            var validityStr = ""
            if let expiry = self.right?.expiry {
                self.rightTypes.append(.validity)
                validityStr = expiry.description
            }
         
            self.watermarkLab.stringValue = watermarkStr
            self.validityLab.stringValue = validityStr
            self.rightsCollection.reloadData()
            
            if watermarkStr.isEmpty == true || watermarkStr.count == 0 {
                self.watermarkText.isHidden  = true
            }else{
                self.watermarkText.isHidden  = false
            }
            
            if validityStr.isEmpty == true || validityStr.count == 0 {
                self.validityText.isHidden  = true
            }else{
                self.validityText.isHidden  = false
            }
            
//            self.view.wantsLayer = true
//            self.view.layer?.backgroundColor = NSColor.red.cgColor
           
        }
    }
    fileprivate var rightTypes = [NXRightType]()
    
    var tags = [String: [String]]() {
        didSet {
            if tags.keys.count != 0 {
                if let contentSize = self.tagsCollectionView.collectionViewLayout?.collectionViewContentSize {
                    self.tagsCollectionView.setFrameSize(contentSize)
                }
                tagsCollectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        rightsCollection.backgroundColors = [NSColor.init(colorWithHex: "#F2F2F2")!]
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.init(colorWithHex: "#F2F2F2")?.cgColor
        
        tagsCollectionView.register(NXResultTagsCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXResultTagsCollectionViewItemID"))
        rightsCollection.register(RightsViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("RightsViewItem"))
        
        location()
    }
    //International adaptation
    fileprivate func location() {
        //需要修改
        definedTypeLab.stringValue = "FILE_RIGHT_COMPANY_DEFINED".localized
        descLab.stringValue = "FILE_RIGHT_COMPANY_POLICIES".localized
        rightsDescLab.stringValue = "FILE_RIGHT_PERMISSIONS".localized
        watermarkText.stringValue = "FILE_RIGHT_WATERMARK".localized
        validityText.stringValue = "FILE_RIGHT_EXPIRATION".localized
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
      
        configureCollectionView()
    }
    
    private func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        let width = (rightsCollection.bounds.width - (CGFloat(Constant.rightCountInRow - 1)) * Constant.standardInterval) / CGFloat(Constant.rightCountInRow)
    
        flowLayout.itemSize = NSSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        rightsCollection.collectionViewLayout = flowLayout
    }
}

extension NXTagsViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.tagsCollectionView {
            return tags.keys.count
        }
        return rightTypes.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        if collectionView == self.tagsCollectionView {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.tagsCollectionItemIdentifier), for: indexPath)
            
            guard let viewItem = item as? NXResultTagsCollectionViewItem else {
                return item
            }
            
            let keys = Array(tags.keys)
            let key  = keys[indexPath.item]
            let labels = tags[key]
            if labels?.count == 1 {
                let tagDisplay = key + ": " + (labels?.first!)!
                viewItem.setLabelDisplay(tagString: tagDisplay)
            }else if labels?.count ?? 0 >= 2 {
                var labStr = ""
                for (index,str) in (labels?.enumerated())! {
                    if index == (labels?.count)! - 1 {
                        labStr = labStr + str
                    }else{
                        labStr = labStr + str + ","
                    }
                }
                  let tagDisplay = key + ": " +  labStr
                  viewItem.setLabelDisplay(tagString: tagDisplay)
            }
            return viewItem
        }else {
            
               let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.rightsCollectionViewItemIdentifier), for: indexPath)
            
            guard let viewItem = item as? RightsViewItem else {
                return item
            }
            
            let right = rightTypes[indexPath.item]
            switch right {
            case .view:
                viewItem.imageView?.image = NSImage(named: "localView")
            case .share:
                viewItem.imageView?.image = NSImage(named: "localReshare")
            case .print:
                viewItem.imageView?.image = NSImage(named: "localPrint")
            case .saveAs:
                viewItem.imageView?.image = NSImage(named:  "localSaveAs")
            case .edit:
                viewItem.imageView?.image = NSImage(named:  "localEdit")
            case .watermark:
                viewItem.imageView?.image = NSImage(named:  "localWatermark")
            case .validity:
                viewItem.imageView?.image = NSImage(named:  "localValidity")
            case .extract:
                viewItem.imageView?.image = NSImage(named: "localextract")
            }
            
            return viewItem
        }
    }
}

extension NXTagsViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        Swift.print(indexPaths)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}

extension NXTagsViewController : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {

        if collectionView == self.tagsCollectionView {
            let keys = Array((tags.keys))
            let key  = keys[indexPath.item]
            let labels = tags[key]
            if labels?.count == 1 {
                let tagDisplay = labels!.first! + key
                let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 500, height: CGFloat.greatestFiniteMagnitude))
                return NSSize(width: 590,height: size.height + 12)
            }else if labels?.count ?? 0 >= 2 {
                var labStr = ""
                for (index,str) in (labels?.enumerated())! {
                    if index == (labels?.count)! - 1 {
                        labStr = labStr + str
                    }else{
                        labStr = labStr + str + ","
                    }
                }
                let tagDisplay = labStr + key
                let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 500, height: CGFloat.greatestFiniteMagnitude))
                return NSSize(width: 590,height: size.height + 12)
            }else{
                return NSSize(width: 590,height: 12)
            }
        }else{
              return NSSize(width: 80,height: 80)
        }
    }
}
