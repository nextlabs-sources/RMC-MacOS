//
//  NXLocalRightsViewController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/26/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXLocalRightsViewController: NSViewController {
    fileprivate struct Constant{
        static let collectionViewItemIdentifier = "RightsViewItem"
        static let standardInterval: CGFloat = 8
        static let rightCountInRow = 6
    }
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var textLabel: NSTextField!
    
    var rights:[NXRightType]?{
        didSet{
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    var textLabelValue:String=""{
        didSet{
            textLabel.stringValue = textLabelValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.delegate = self
        collectionView.dataSource = self
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.color(withHexColor: "#F2F2F2").cgColor
        
        collectionView.register(RightsViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier))
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        configureCollectionView()
    }
    
    fileprivate func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        let width = (collectionView.bounds.width - (CGFloat(Constant.rightCountInRow - 1)) * Constant.standardInterval) / CGFloat(Constant.rightCountInRow)
        flowLayout.itemSize = NSSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXLocalRightsViewController:NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return rights?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard rights != nil else{
            let item = NSCollectionViewItem()
            return item
        }
        
        var item:NSCollectionViewItem
        
        item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        return item
    }
}
extension NXLocalRightsViewController: NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        
    }
}
