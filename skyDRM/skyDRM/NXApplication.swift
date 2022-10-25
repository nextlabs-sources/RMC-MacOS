//
//  NXApplication.swift
//  skyDRM
//
//  Created by helpdesk on 3/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

@objc(NXApplication)
class NXApplication: NSApplication {
    override init(){
        super.init()
        NXInitHPSCpp2OC.initWorld()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
