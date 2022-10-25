//
//  NXLocalFileInfoInfoViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 01/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXLocalFileInfoInfoViewController: NSViewController {
    @IBOutlet weak var fileNameLbl: NSTextField!
    @IBOutlet weak var sizeLbl: NSTextField!
    @IBOutlet weak var lastModifiedLbl: NSTextField!
    @IBOutlet weak var originalPathLbl: NSTextField!
    @IBOutlet weak var sharedWithLbl: NSTextField!
    @IBOutlet weak var sharedWithCollectionView: NSCollectionView!
    
    @IBOutlet weak var modifyTime: NSTextField!
    @IBOutlet weak var fileSize: NSTextField!
    
    @IBOutlet weak var originalFileText: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    fileprivate struct Constant {
        static let collectionViewItemIdentifier = "NXLocalSharedCollectionViewItem"
        static let itemHeight: CGFloat = 54
        static let standardInterval: CGFloat = 5
        static let leftMargin: CGFloat = 20
    }
    
    var file: NXNXLFile!
    
    var sharedWith: [String] {
        get {
            return file.recipients ?? []
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")!.cgColor
        self.sharedWithCollectionView.backgroundColors = [NSColor(colorWithHex: "#ECECEC")!]
        
        settingFileInfo()
        settingSharedWith()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        location()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        settingCollectionFlowLayout()
    }
    
    private func settingFileInfo() {
        fileNameLbl.stringValue = file.name
        fileNameLbl.lineBreakMode = .byTruncatingMiddle
        sizeLbl.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
        lastModifiedLbl.stringValue = formatDateToString(date: file.lastModifiedDate as Date)
        
        if let originalPath = file.originFilePath, originalPath != "" {
            originalPathLbl.stringValue = originalPath
        } else {
            originalPathLbl.stringValue = file.name
        }
        
    }
    
    private func settingSharedWith() {
        if sharedWith.count > 1 {
            sharedWithLbl.stringValue = String.init(format: "LOCAL_FILEINFO_INFO_SHARED_WITH_S".localized, sharedWith.count)
        } else {
            sharedWithLbl.stringValue = String.init(format: "LOCAL_FILEINFO_INFO_SHARED_WITH".localized, sharedWith.count)
        }
        
        if let istagFile = file.isTagFile {
            if istagFile {
                sharedWithLbl.isHidden = true
            }
        }
        
        sharedWithCollectionView.dataSource = self
        sharedWithCollectionView.delegate = self
      // settingCollectionFlowLayout()
    }
    
    private func settingCollectionFlowLayout() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: (self.view.bounds.width - 10 - Constant.leftMargin - 5 * Constant.standardInterval)/3, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: 0, bottom: Constant.standardInterval, right: 0)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        sharedWithCollectionView.collectionViewLayout = flowLayout
    }
    fileprivate func location() {
        fileSize.stringValue = "FILE_INFO_SIZE".localized
        modifyTime.stringValue = "FILE_INFO_MODIFIEDTIME".localized
        originalFileText.stringValue = "FILE_INFO_ORIGINAL".localized
    }
}


extension NXLocalFileInfoInfoViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sharedWith.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        if let sharedItem = viewItem as? NXLocalSharedCollectionViewItem {
            sharedItem.email = sharedWith[indexPath.item]
        }
        
        return viewItem
    }
    
}

extension NXLocalFileInfoInfoViewController {
    fileprivate func formatDateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
}

extension NXLocalFileInfoInfoViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        Swift.print(indexPaths)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}
