//
//  NXRepositoryItem.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXRepositoryItem: NSCollectionViewItem {

    @IBOutlet weak var serviceType: NSImageView!
    @IBOutlet weak var serviceAlias: NSTextField!
    @IBOutlet weak var accountName: NSTextField!
    weak var delegate: NXRepositoryItemDelegate?
    var id: Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        accountName.textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    @IBAction func onMoreButton(_ sender: Any) {
        delegate?.onMoreButton(id: id)
    }
    
}
