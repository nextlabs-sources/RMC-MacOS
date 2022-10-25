//
//  NXWelcomeInfoViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

struct NXWelcomeInfo {
    var imageName = ""
    var firstLine = ""
    var secondLine = ""
    var thirdLine = ""
    var info = ""
    
    init(imageName: String, firstLine: String, secondLine: String, thirdLine: String, info: String) {
        self.imageName = imageName
        self.firstLine = firstLine
        self.secondLine = secondLine
        self.thirdLine = thirdLine
        self.info = info
    }
    init() {
    }
}

class NXWelcomeInfoViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var firstLabel: NSTextField!
    @IBOutlet weak var secondLabel: NSTextField!
    @IBOutlet weak var thirdLabel: NSTextField!
    @IBOutlet weak var introLabel: NSTextField!
    var welcomeInfo = NXWelcomeInfo() {
        willSet {
            DispatchQueue.main.async {
                self.imageView.image = NSImage(named: newValue.imageName)
                self.firstLabel.stringValue = newValue.firstLine
                self.secondLabel.stringValue = newValue.secondLine
                self.thirdLabel.stringValue = newValue.thirdLine
                self.introLabel.stringValue = newValue.info
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}
