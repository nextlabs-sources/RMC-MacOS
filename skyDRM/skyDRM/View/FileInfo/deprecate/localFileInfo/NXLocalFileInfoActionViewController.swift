//
//  NXLocalFileInfoActionViewController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/26/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXLocalFileInfoActionViewControllerDelegate: NSObjectProtocol {
    func protect()
    func share()
}

class NXLocalFileInfoActionViewController: NSViewController {
    fileprivate struct Constant{
        static let protectViewControllerXibName = "NXProtectViewController"
    }
    
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var shareBtn: NSButton!
    
    var file:NXFileBase?
    weak var delegate: NXLocalFileInfoActionViewControllerDelegate?
    
    func createProtectViewController()->NXProtectViewController?{
        let protectViewController = NXProtectViewController(nibName: Constant.protectViewControllerXibName, bundle: nil)
        protectViewController.file = file
        return protectViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        protectBtn.wantsLayer = true
        protectBtn.layer?.cornerRadius = 4
        protectBtn.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
        protectBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        protectBtn.layer?.borderWidth = 1
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let protectString = NSLocalizedString("FILEINFO_PROTECT", comment: "")
        protectBtn.title = protectString
        
        shareBtn.wantsLayer = true
        shareBtn.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
        shareBtn.layer?.cornerRadius = 4
        shareBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        shareBtn.layer?.borderWidth = 1
        let shareString = NSLocalizedString("FILEINFO_SHARE", comment: "")
        shareBtn.title = shareString
    }
    
    @IBAction func protectClick(_ sender: Any) {
        delegate?.protect()
    }
    
    @IBAction func shareClick(_ sender: Any) {
        delegate?.share()
    }
}
