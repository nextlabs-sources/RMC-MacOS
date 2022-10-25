//
//  NXSpecificProjectHomePolicyView.swift
//  skyDRM
//
//  Created by helpdesk on 2/28/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomePolicyView: NSView {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var addBtn: NSButton!
    
    struct Constant{
        static let collectionViewItemIdentifier = "NXSpecificProjectHomePolicyItem"
        static let itemHeight: CGFloat = 100.0
        static let standardInterval: CGFloat = 0.0
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    open func doWork(){
        collectionView.layer?.backgroundColor = WHITE_COLOR.cgColor
        configureCollectionView()
        addBtn.title = NSLocalizedString("PROJECT_ADD_POLICY_TITLE", comment: "")
        addBtn.wantsLayer = true
        addBtn.layer?.backgroundColor = NSColor.white.cgColor
        addBtn.layer?.cornerRadius = 5
        addBtn.layer?.masksToBounds = true
        addBtn.layer?.shadowColor = NSColor.black.cgColor
        addBtn.layer?.shadowOpacity = 0.1
        addBtn.layer?.borderWidth = 0.3
        addBtn.layer?.borderColor = NSColor.black.cgColor
        addBtn.layer?.shadowOffset = CGSize(width: 3, height: 5)
    }
    
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: self.bounds.width - 2 * Constant.standardInterval, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        collectionView.collectionViewLayout = flowLayout
    }
    
    @IBAction func addPolicy(_ sender: Any) {
        
    }
    @IBAction func viewAllPolicy(_ sender: Any) {
        
    }
}

extension NXSpecificProjectHomePolicyView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 11
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem{
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        
        return viewItem
    }
}

extension NXSpecificProjectHomePolicyView: NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}

