//
//  NXAddRepositoryItem.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXAddRepositoryItem: NSCollectionViewItem {
    weak var delegate: NXAddRepositoryItemDelegate?
    private let backgroundView = NXAddRepoBackgroundView()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillDisappear() {
        super.viewWillDisappear()
        backgroundView.removeFromSuperview()
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        view.wantsLayer = true
        backgroundView.frame = view.frame
        view.addSubview(backgroundView)
        
        let text = NSTextField()
        text.isBezeled = false
        text.drawsBackground = false
        text.isEditable = false
        
        text.stringValue = NSLocalizedString("REPOSITORY_ADD", comment: "")
        text.textColor = NSColor.white
        text.font = NSFont(name: "Arial", size: 16)
        text.frame = NSMakeRect((view.frame.width - text.fittingSize.width)/2, 30, text.fittingSize.width, text.fittingSize.height)
        view.addSubview(text)
    }
    
    override func mouseDown(with event: NSEvent) {
        delegate?.addRepo()
        super.mouseDown(with: event)
    }
}
