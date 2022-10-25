//
//  NXHomeCollectionView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/2.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeCollectionViewDelegate: NSObjectProtocol {
    func onAuth(id: Int)
    func onMouseDown(id: Int)
}

class NXHomeCollectionView: NXScrollWheelCollectionView {
    struct UIConstant {
        static let itemHeight: CGFloat = 50.0
        static let itemWidth: CGFloat = 240.0
        static let rowGap: CGFloat = 10.0
        static let itemGap: CGFloat = 10.0
        static let labelHeight: CGFloat = 20.0
        static let labeleCollectionGap: CGFloat = 20.0
    }
    var repoItems = [NXRMCRepoItem](){
        didSet {
            self.reloadData()
        }
    }

    weak var collectionDelegate: NXHomeCollectionViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            let flowLayout = NSCollectionViewFlowLayout()
            flowLayout.itemSize = NSSize(width: UIConstant.itemWidth, height: UIConstant.itemHeight)
            flowLayout.minimumInteritemSpacing = UIConstant.itemGap
            flowLayout.minimumLineSpacing = UIConstant.rowGap
            flowLayout.sectionInset = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            flowLayout.scrollDirection = .vertical
            flowLayout.headerReferenceSize = NSZeroSize
            flowLayout.footerReferenceSize = NSZeroSize
            self.collectionViewLayout = flowLayout
            self.dataSource = self
        }
    }

}
extension NXHomeCollectionView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return repoItems.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXHomeRepositoryItem"), for: indexPath)
        guard let repoItem = item as? NXHomeRepositoryItem else {
            return item
        }
        let repo = repoItems[indexPath.item]
        let cloudName = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: repo.type.rawValue)
        repoItem.image = NSImage(named:  cloudName)
        repoItem.alias = repo.name
        repoItem.accountName = repo.accountName
        repoItem.isAuthed = repo.isAuth
        repoItem.id = indexPath.item
        repoItem.delegate = self
        return repoItem
    }
}

extension NXHomeCollectionView: NXHomeRepositoryItemDelegate {
    func onAuth(id: Int) {
        collectionDelegate?.onAuth(id: id)
    }
    func onMouseDown(id: Int) {
        collectionDelegate?.onMouseDown(id: id)
    }
}

