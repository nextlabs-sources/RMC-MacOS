//
//  NXFileSharingManageViewItem.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 16/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXFileSharingManageViewItemDelegate: NSObjectProtocol {
    func removeItem(with item: NSCollectionViewItem)
}

class NXFileSharingManageViewItem: NSCollectionViewItem {

    @IBOutlet weak var icon: NXCircleText!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var closeBtn: NSButton!
    
    weak var delegate: NXFileSharingManageViewItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        view.wantsLayer = true
        view.layer?.borderColor = NSColor(colorWithHex: "#F2F3F5", alpha: 1.0)?.cgColor
        view.layer?.borderWidth = 2
        
        view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    @IBAction func removeItem(_ sender: Any) {
        delegate?.removeItem(with: self)
    }
}
