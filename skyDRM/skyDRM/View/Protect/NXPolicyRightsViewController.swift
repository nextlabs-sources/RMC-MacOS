//
//  RightsViewController.swift
//  FileInfoDemo
//
//  Created by pchen on 03/03/2017.
//  Copyright © 2017 CQ. All rights reserved.
//

import Cocoa

class PolicyRightsViewController: NSViewController {

    struct Constant {
        static let collectionViewItemIdentifier = "NXPolicyRightsViewItem"
        static let standardInterval: CGFloat = 8
        static let rightCountInRow = 6
    }
    @IBOutlet weak var headerTitle: NSTextField!
    
    @IBOutlet weak var descriptionText: NSTextField!
    
    @IBOutlet weak var collectionView: NSCollectionView!

    @IBOutlet weak var waterMarkText: NSTextField!
    @IBOutlet weak var watermarkLbl: NSTextField!
    @IBOutlet weak var validityLbl: NSTextField!

    @IBOutlet weak var validityText: NSTextField!
    @IBOutlet weak var accessDeniedView: NSView!
    @IBOutlet weak var accessDeniedLab: NSTextField!
    @IBOutlet weak var deniedDescLab: NSTextField!
    
    var type: FileInfoType?
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
            DispatchQueue.main.async {
                self.watermarkLbl.stringValue = watermarkStr
                self.validityLbl.stringValue = validityStr
                self.collectionView.reloadData()
            }
            
        }
    }
    
    fileprivate var rightTypes = [NXRightType]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColors = [NSColor.init(colorWithHex: "#F2F2F2")!]
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.init(colorWithHex: "#F2F2F2")?.cgColor
        location()
    }
    //International adaptation
    fileprivate func location() {
        headerTitle.stringValue = "FILE_RIGHT_USER_DEFINED".localized
        descriptionText.stringValue = "FILE_RIGHT_PERMISSIONS".localized
        waterMarkText.stringValue = "FILE_RIGHT_WATERMARK".localized
        validityText.stringValue = "FILE_RIGHT_EXPIRATION".localized
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if type == .noViewRight {
            headerTitle.isHidden = true
            descriptionText.isHidden = true
            collectionView.isHidden = true
            accessDeniedView.isHidden = false
            waterMarkText.isHidden = true
            watermarkLbl.isHidden  = true
            validityText.isHidden = true
            validityLbl.isHidden = true
        }
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
        let width = (collectionView.bounds.width - (CGFloat(Constant.rightCountInRow - 1)) * Constant.standardInterval) / CGFloat(Constant.rightCountInRow)
        flowLayout.itemSize = NSSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        collectionView.collectionViewLayout = flowLayout
    }
}

extension PolicyRightsViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return rightTypes.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        
        let right = rightTypes[indexPath.item]
        switch right {
        case .view:
            item.imageView?.image = NSImage(named:  "localView")
        case .share:
            item.imageView?.image = NSImage(named:  "localReshare")
        case .print:
            item.imageView?.image = NSImage(named:  "localPrint")
        case .saveAs:
            item.imageView?.image = NSImage(named:  "localSaveAs")
        case .edit:
            item.imageView?.image = NSImage(named:  "localEdit")
        case .watermark:
            item.imageView?.image = NSImage(named:"localWatermark")
        case .validity:
            item.imageView?.image = NSImage(named:"localValidity")
        case .extract:
            item.imageView?.image = NSImage(named: "localextract")
        }
        
        return item
    }
}

extension PolicyRightsViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        Swift.print(indexPaths)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}
