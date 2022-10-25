//
//  NXSpecificProjectHomeReportsView.swift
//  skyDRM
//
//  Created by helpdesk on 2/28/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomeReportsView: NSView {
    @IBOutlet weak var collectionView: NSCollectionView!
    
    struct Constant{
        static let collectionViewItemIdentifier = "NXSpecificProjectHomeReportsView"
        static let itemHeight: CGFloat = 50.0
        static let standardInterval: CGFloat = 0.0
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    open func doWork(){
        collectionView.layer?.backgroundColor = WHITE_COLOR.cgColor
        configureCollectionView()
    }
    
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: self.bounds.width - 2 * Constant.standardInterval, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXSpecificProjectHomeReportsView: NSCollectionViewDataSource{
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

extension NXSpecificProjectHomeReportsView: NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}
