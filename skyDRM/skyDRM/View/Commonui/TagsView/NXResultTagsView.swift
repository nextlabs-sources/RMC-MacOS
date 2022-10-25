//
//  NXResultTagsView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/4/10.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXResultTagsView: NSView {

    @IBOutlet weak var collectionView: NSCollectionView!
    
    var tags = [String: [String]]() {
        didSet {
            if tags.keys.count != 0 {
                collectionView.reloadData()
            }
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToSuperview()
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = NSColor.white.cgColor
        collectionView.register(NXResultTagsCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXResultTagsCollectionViewItemID"))
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 550, height: 30)
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXResultTagsView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.keys.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier.init("NXResultTagsCollectionViewItemID"), for: indexPath)
        guard let viewItem = item as? NXResultTagsCollectionViewItem else {
            return item
        }
        let keys = Array(tags.keys)
        let key  = keys[indexPath.item]
        let labels = tags[key]
        if labels?.count == 1 {
            let tagDisplay = key + ": " + (labels?.first)!
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
             let tagDisplay = key + ": " + labStr
             viewItem.setLabelDisplay(tagString: tagDisplay)
        }
        return viewItem
    }
}

extension NXResultTagsView : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let keys = Array((tags.keys))
        let key  = keys[indexPath.item]
        let labels = tags[key]
        if labels?.count == 1 {
            let tagDisplay = labels!.first! + key
            let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 500, height: CGFloat.greatestFiniteMagnitude))
            return NSSize(width: 580,height: size.height + 12)
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
            return NSSize(width: 580,height: size.height + 12)
        }else{
            return NSSize(width: 580,height: 30)
        }
    }
}
