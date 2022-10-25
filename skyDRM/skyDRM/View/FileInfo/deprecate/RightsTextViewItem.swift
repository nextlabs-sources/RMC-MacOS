//
//  RightsTextViewItem.swift
//  skyDRM
//
//  Created by pchen on 10/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

/// - Note: This method is Deprecated, Use RightsViewItem instead.
class RightsTextViewItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        view.wantsLayer = true
        view.layer?.cornerRadius = view.bounds.width/2
        view.layer?.backgroundColor = NSColor.init(colorWithHex: "#F2F2F2", alpha: 1.0)?.cgColor
    }
}
