//
//  NXRightViewOnly.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 04/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXRightViewOnly: NSView {
    fileprivate struct Constant{
        static let collectionViewItemIdentifier = "NXLocalRightsViewItem"
        static let standardInterval: CGFloat = 3
        static let rightCountInRow = 8
    }
    @IBOutlet weak var validityLabel: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var watermarkTag: NSTextField!
    @IBOutlet weak var watermarkLabel: NSTextField!
    @IBOutlet weak var validityLab: NSTextField!
    @IBOutlet weak var accessDeineView: NSView!
    
    @IBOutlet weak var lineView: NSBox!
    
    var ItemCountMax:CGFloat = 8
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var validyLabelTopToLineBottomConstant: NSLayoutConstraint!
    @IBOutlet weak var validityTagTopToLineBottomConstant: NSLayoutConstraint!
    
    var rightsCollectionViewItemSize :NSSize?
    
    var right: NXRightObligation? {
        didSet{
            guard let right = self.right else {
                return
            }
            if !right.rights.contains(NXRightType.view){
                accessDeineView.isHidden = false
            }else{
                accessDeineView.isHidden = true
            }
         
            if let expiry = right.expiry,
                !NXClient.isExpiry(expiry: expiry) {
                var rights = right.rights
                rights.append(.validity)
                self.sortedRightTypes = rights
                
            } else {
                self.sortedRightTypes = right.rights
            }
            
              configureCollectionView()
                self.collectionView.reloadData()
                if let watermark = right.watermark {
                    let description = watermark.text //NXCommonUtils.getWatermarkDescription(from: watermark.text)
                    self.watermarkTag.isHidden = false
                    self.watermarkLabel.stringValue = description
                    self.validityTagTopToLineBottomConstant.constant = 26
                    validyLabelTopToLineBottomConstant.constant = 26
                }else{
                    self.watermarkTag.isHidden = true
                    self.validityTagTopToLineBottomConstant.constant = 5
                    validyLabelTopToLineBottomConstant.constant = 5
                }
                
                if let expiry = right.expiry {
                    self.validityLab.isHidden = false
                    self.validityLabel.stringValue = expiry.description
                }else
                {
                    self.validityLab.isHidden = true
                }
        }
    }
    
    var sortedRightTypes = [NXRightType]()
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if self.window == nil {
            return
        }
        
        collectionView.register(NXLocalRightsViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXLocalRightsViewItem"))
        
        collectionView.delegate = self
        collectionView.dataSource = self
        wantsLayer = true
        layer?.backgroundColor = NSColor.color(withHexColor: "#F2F2F2").cgColor
        configureCollectionView()
        
        
       
    }
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        let superViewWidth = self.superview?.frame.size.width
        var currentViewWidth  = self.bounds.size.width
        
        if let width = superViewWidth {
            currentViewWidth = width
        }
        let width = (currentViewWidth - 20 - (CGFloat(ItemCountMax - 1)) * Constant.standardInterval) / CGFloat(ItemCountMax)
        
        flowLayout.itemSize = NSSize(width: width, height: 100)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        rightsCollectionViewItemSize = NSSize(width: width, height: 100)
        collectionView.collectionViewLayout = flowLayout
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
    }
    
}
extension NXRightViewOnly: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedRightTypes.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        if let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath) as? NXLocalRightsViewItem {
            var image: NSImage?
            var text: String?
            switch sortedRightTypes[indexPath.item] {
            case .view:
                image = NSImage.init(named:  "view")
                text = "View"
            case .print:
                image = NSImage.init(named:  "print")
                text = "Print"
            case .share:
                image = NSImage.init(named: "share")
                text = "Re-share"
            case .saveAs:
                image = NSImage.init(named:  "saveas")
                text = "SaveAs"
            case .edit:
                image = NSImage.init(named:  "edit")
                text = "Edit"
            case .watermark:
                image = NSImage.init(named: "watermark")
                text = "Watermark"
            case .validity:
                image = NSImage.init(named: "validity")
                text = "Validity"
            case .extract:
                image = NSImage.init(named: "extract")
                text = "Extract"
            }
            
            item.imageView?.image = image
            item.textField?.stringValue = text ?? ""
            return item
        }
        
        let item = NSCollectionViewItem()
        return item
        
    }
}
extension NXRightViewOnly: NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        
    }
}

//extension NXRightViewOnly: NSCollectionViewDelegateFlowLayout {

//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
//
//        let width = (self.bounds.width - 20 - (CGFloat(sortedRightTypes.count - 1)) * Constant.standardInterval) / CGFloat(sortedRightTypes.count)
//        return  NSSize(width: width,height:100.0)
//    }
//}

