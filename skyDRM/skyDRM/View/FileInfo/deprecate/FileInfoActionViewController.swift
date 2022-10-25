//
//  FileActionViewController.swift
//  FileInfoDemo
//
//  Created by pchen on 03/03/2017.
//  Copyright © 2017 CQ. All rights reserved.
//

import Cocoa

protocol FileInfoActionViewControllerDelegate: NSObjectProtocol {
    func protect()
    func share()
}

class FileInfoActionViewController: NSViewController {

    private struct Constant {
        static let protectViewContrllerXibName = "NXProtectViewController"
        
        // Display message
        static let protectTitle = NSLocalizedString("FILEINFO_PROTECT", comment: "")
        static let shareTitle = NSLocalizedString("FILEINFO_SHARE", comment: "")
    }
    
    @IBOutlet weak var protectBtn: NSButton!
    
    @IBOutlet weak var shareBtn: NSButton!
    
    var file: NXFileBase?
    
    weak var delegate: FileInfoActionViewControllerDelegate?
    
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
        protectBtn.title = Constant.protectTitle
        
        shareBtn.wantsLayer = true
        shareBtn.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
        shareBtn.layer?.cornerRadius = 4
        shareBtn.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        shareBtn.layer?.borderWidth = 1
        shareBtn.title = Constant.shareTitle
    }
    
    @IBAction func protect(_ sender: Any) {
        delegate?.protect()
    }
    
    @IBAction func share(_ sender: Any) {
        delegate?.share()
    }
    
    func createProtectViewController() -> NXProtectViewController? {
        let protectViewController = NXProtectViewController(nibName: Constant.protectViewContrllerXibName, bundle: nil)
        
        protectViewController.file = file
        
        return protectViewController
    }
}
