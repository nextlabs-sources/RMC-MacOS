//
//  NXHomeRepositoryItem.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/28.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeRepositoryItemDelegate: NSObjectProtocol {
    func onAuth(id: Int)
    func onMouseDown(id: Int)
}

class NXHomeRepositoryItem: NSCollectionViewItem {

    @IBOutlet weak var repoImageView: NXMouseEventImageView!
    @IBOutlet weak var aliasLabel: NXMouseEventTextField!
    @IBOutlet weak var accountLabel: NXMouseEventTextField!
    @IBOutlet weak var authBtn: NSButton!
    var id: Int = -1
    
    weak var delegate: NXHomeRepositoryItemDelegate?
    
    var image: NSImage? {
        willSet {
            DispatchQueue.main.async {
                self.repoImageView.image = newValue
            }
        }
    }
    var alias = "" {
        willSet {
            DispatchQueue.main.async {
                self.aliasLabel.textColor = NSColor.black
                self.aliasLabel.stringValue = newValue
                self.aliasLabel.toolTip = newValue
            }
        }
    }
    var accountName = "" {
        willSet {
            DispatchQueue.main.async {
                self.accountLabel.stringValue = newValue
                self.accountLabel.toolTip = newValue
            }
        }
    }
    var isAuthed = false {
        willSet {
            DispatchQueue.main.async {
                self.authBtn.isHidden = newValue
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        repoImageView.wantsLayer = true
        repoImageView.layer?.backgroundColor = NSColor(colorWithHex: "#F2F3F5", alpha: 1.0)?.cgColor
        repoImageView.mouseDelegate = self
        accountLabel.mouseDelegate = self
        aliasLabel.mouseDelegate = self
        authBtn.toolTip = NSLocalizedString("HOME_REPOSITORY_TIP", comment: "")
        view.wantsLayer = true
        view.layer?.borderWidth = 0.3
        view.layer?.cornerRadius = view.frame.height/8
    }

    @IBAction func onAuth(_ sender: Any) {
        delegate?.onAuth(id: id)
    }
}

extension NXHomeRepositoryItem: NXMouseEventImageViewDelegate {
    func mouseDownImageView(sender: Any, event: NSEvent) {
        delegate?.onMouseDown(id: id)
    }
}

extension NXHomeRepositoryItem: NXMouseEventTextFieldDelegate {
    func mouseDownTextField(sender: Any, event: NSEvent) {
        delegate?.onMouseDown(id: id)
    }
}
