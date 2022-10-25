//
//  ProjectHasPeopleItem.swift
//  skyDRM
//
//  Created by helpdesk on 3/2/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXAllProjectPeopleSubItem: NSCollectionViewItem {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {
        self.view = NXAllProjectPeopleCircleView(frame: NSZeroRect)
    }
}
