//
//  NXProjectActivateIntroVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

struct NXProjectActivateInfo {
    var imageName = ""
    var firstLine = ""
    var secondLine = ""
    var info = ""
    
    init(imageName: String, firstLine: String, secondLine: String, info: String) {
        self.imageName = imageName
        self.firstLine = firstLine
        self.secondLine = secondLine
        self.info = info
    }
    init() {
    }
}

class NXProjectActivateIntroVC: NSViewController {

    @IBOutlet weak var firstLabel: NSTextField!
    @IBOutlet weak var secondLabel: NSTextField!
    @IBOutlet weak var introLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    var activateInfo = NXProjectActivateInfo() {
        willSet {
            DispatchQueue.main.async {
                self.imageView.image = NSImage(named: newValue.imageName)
                self.firstLabel.stringValue = newValue.firstLine
                self.secondLabel.stringValue = newValue.secondLine
                self.introLabel.stringValue = newValue.info
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
