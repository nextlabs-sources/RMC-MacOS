//
//  NXConnectedRepoVC.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXConnectedRepositoryView: NSView, NSCollectionViewDataSource {
    
    @IBOutlet weak var ConnectedRepositoryLabel: NSTextField!
    @IBOutlet weak var repoCollection: NSCollectionView!
    @IBOutlet weak var closeBtn: NSButton!
    
    var repos = [NXRMCRepoItem]()
    weak var delegate: NXRepositoryActionDelegate?
    override func viewDidMoveToWindow() {
        self.window?.backgroundColor = BK_COLOR
        guard let frame = self.window?.frame else {
            return
        }
        self.window?.setFrame(NSMakeRect(frame.minX, frame.minY, 960, 515), display: true)
        adjustWindowPosition(with: NXCommonUtils.getMainWindow())
    }
    
    private func adjustWindowPosition(with parentWindow: NSWindow?) {
        guard
            let currentWindow = self.window,
            let parentWindow = parentWindow
            else { return }
        
        let x = (parentWindow.frame.width - currentWindow.frame.width)/2
        let y = (parentWindow.frame.height - currentWindow.frame.height)/2
        currentWindow.setFrameOrigin(CGPoint(x: parentWindow.frame.origin.x + x, y: parentWindow.frame.origin.y + y))
    }
    
    override func viewDidMoveToSuperview() {
        guard superview != nil else {
            return
        }
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200, height: 160)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        repoCollection.collectionViewLayout = flowLayout
        // 2
        repoCollection.layer?.backgroundColor = BK_COLOR.cgColor
        
        self.wantsLayer = true
        self.layer?.backgroundColor = BK_COLOR.cgColor
        self.ConnectedRepositoryLabel.stringValue = NSLocalizedString("REPOSITORY_CONNECTED", comment: "")
        self.repos = NXLoginUser.sharedInstance.repository()
        repoCollection.reloadData()
        
    }

    @IBAction func onClose(_ sender: Any) {
        delegate?.closeConnectedView()
    }
    //Mark: NSCollectionViewDataSource
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return repos.count + 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if  indexPath.item == 0 {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXAddRepositoryItem"), for: indexPath)
            guard let addItem = item as? NXAddRepositoryItem else {
                return item
            }
            addItem.delegate = self
            return addItem
        }
        else {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXRepositoryItem"), for: indexPath)
            guard let repoItem = item as? NXRepositoryItem else {
                return item
            }
            let repo = repos[indexPath.item - 1]
            let cloudName = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: Int32(repo.type.rawValue))
            repoItem.serviceType.image = NSImage(named:  cloudName)
            repoItem.serviceAlias.stringValue = repo.name
            repoItem.accountName.stringValue = repo.accountName
            repoItem.id = indexPath.item - 1
            repoItem.delegate = self
            return repoItem
        }
    }
}

extension NXConnectedRepositoryView: NXAddRepositoryItemDelegate {
    func addRepo() {
        delegate?.openAddView()
    }
}

extension NXConnectedRepositoryView: NXRepositoryItemDelegate {
    func onMoreButton(id: Int) {
        if id < repos.count {
            delegate?.openManageView(currentRepo: repos[id],AllRepo:repos)
        }
    }
}
