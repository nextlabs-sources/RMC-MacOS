//
//  NXRightTypeView.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 20/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXRightTypeView: NSView {

    struct Constant {
        static let collectionViewItemIdentifier = "NXLocalRightsViewItem"
        static let standardInterval: CGFloat = 8
        static let rightCountInRow = 6
    }
    
    var collectionView: NSCollectionView?
    
    var types = [NXRightType]() {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        let scrollView = NSScrollView(frame: self.bounds)
        self.addSubview(scrollView)
        
        let collectionView = NSCollectionView(frame: scrollView.bounds)
        self.collectionView = collectionView
        
        configCollectionFlow()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = NSColor.init(colorWithHex: "#F2F2F2")?.cgColor
        
        scrollView.contentView.addSubview(collectionView)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    fileprivate func configCollectionFlow(){
        let flowLayout = NSCollectionViewFlowLayout()
        let width = (collectionView!.bounds.width - (CGFloat(Constant.rightCountInRow - 1)) * Constant.standardInterval) / CGFloat(Constant.rightCountInRow)
        flowLayout.itemSize = NSSize(width: width, height: self.bounds.height)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        self.collectionView?.collectionViewLayout = flowLayout
    }
    
}

extension NXRightTypeView: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return types.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath) as? NXLocalRightsViewItem {
            var image: NSImage?
            var text: String?
            switch types[indexPath.item] {
                case .view:
                    image = NSImage.init(named:  "view")
                    text = "View"
                case .print:
                    image = NSImage.init(named:  "print")
                    text = "Print"
                case .share:
                    image = NSImage.init(named: "share")
                    text = "Reshare"
                case .saveAs:
                    image = NSImage.init(named:  "saveas")
                    text = "SaveAs"
                case .edit:
                    image = NSImage.init(named:"edit")
                    text = "Edit"
                case .watermark:
                    image = NSImage.init(named: "watermark")
                    text = "Watermark"
                case .validity:
                    image = NSImage.init(named:"validity")
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

extension NXRightTypeView: NSCollectionViewDelegate {
    
}
