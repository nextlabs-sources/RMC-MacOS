//
//  NXProjectTagTemplateViewItem.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/25.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProjectTagTemplateViewItemDelegate: NSObjectProtocol {
    func select(_ indexPath: IndexPath, _ item: NSCollectionViewItem) -> ()
}

class NXProjectTagTemplateViewItem: NSCollectionViewItem {

    
    @IBOutlet weak var nameLabel: NSTextField!
    
    
    var indexPath: IndexPath?
    
    weak var delegate: NXProjectTagTemplateViewItemDelegate?
    
    override var isSelected: Bool {
        didSet {
            view.layer?.borderWidth = isSelected ? 2.0 : 0
        }
    }
    
    var labModel: NXProjectTagLabel?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.borderWidth = 0.0
        view.layer?.borderColor = RGB(r: 39, g: 137, b: 251).cgColor
        
        let Tap = NSClickGestureRecognizer(target: self, action: #selector(selectItem(_:)))
        view.addGestureRecognizer(Tap)
    }
    
    @objc func selectItem(_ gesture: NSGestureRecognizer?) {
        delegate?.select(indexPath!, self)
    }
    
}
