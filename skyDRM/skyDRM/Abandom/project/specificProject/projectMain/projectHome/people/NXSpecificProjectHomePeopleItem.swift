//
//  NXSpecificProjectHomePeopleItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomePeopleItem: NSCollectionViewItem {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {
        self.view = NXSpecificProjectHomePeopleCircleText(frame: NSZeroRect)
    }
}
