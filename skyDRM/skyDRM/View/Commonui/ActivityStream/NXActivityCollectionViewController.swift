//
//  CollectionViewController.swift
//  NSCollectionViewDemo
//
//  Created by pchen on 23/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

class NXActivityCollectionViewController: NSViewController {
    
    // TODO: Input Data
    // ...
    
    @IBOutlet weak var titleText: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    struct Constant {
        static let collectionViewItemIdentifier = "NXActivityCollectionViewItem"
        static let collectionSectionHeaderView = "NXActivitySectionHeaderView"
        
        static let headerHeight: CGFloat = 20
        static let itemHeight: CGFloat = 100
        static let standardInterval: CGFloat = 8
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        configureCollectionView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    private func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: view.bounds.width - 2 * Constant.standardInterval, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXActivityCollectionViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 11
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        
        return viewItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionSectionHeaderView), for: indexPath)
        return view
    }
}

extension NXActivityCollectionViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: view.bounds.width, height: Constant.headerHeight)
    }
}

extension NXActivityCollectionViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}
