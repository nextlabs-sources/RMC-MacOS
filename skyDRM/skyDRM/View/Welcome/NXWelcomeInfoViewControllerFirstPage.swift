//
//  NXWelcomeInfoViewControllerFirstPage.swift
//  skyDRM
//
//  Created by Tao on 08/08/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXWelcomeInfoViewControllerFirstPage: NSViewController {
    @IBOutlet weak var toText: NSTextField!
    @IBOutlet weak var hidenText: NSTextField!
    @IBOutlet weak var tipText: NSTextField!
    @IBOutlet weak var digitalRightText: NSTextField!
    @IBOutlet weak var securelyText: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var introLabel: NSTextField!
    var welcomeInfo = NXWelcomeInfo()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
