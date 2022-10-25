//
//  NXSpecificProjectHomePolicyItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/28/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomePolicyItem: NSCollectionViewItem {
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var expireTime: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
