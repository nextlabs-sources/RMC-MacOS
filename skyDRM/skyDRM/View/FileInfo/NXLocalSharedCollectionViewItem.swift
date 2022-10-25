//
//  NXLocalSharedCollectionViewItem.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 01/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXLocalSharedCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var portraitView: NXCircleText!
    @IBOutlet weak var nameLbl: NSTextField!
    @IBOutlet weak var emailLbl: NSTextField!

    // Input
    var email = "" {
        didSet {
            if let range = email.range(of: "@") {
                let name = email[email.startIndex..<range.lowerBound]
                let abbrev = NXCommonUtils.abbreviation(forUserName: String(name))
                self.name = String(name)
                self.abbrev = abbrev
            }
            
            DispatchQueue.main.async {
                self.updateView()
            }
            
        }
    }
    
    var abbrev = ""
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        view.wantsLayer = true
        nameLbl.wantsLayer = true
        view.layer?.borderColor = NSColor(colorWithHex: "#F2F3F5", alpha: 1.0)?.cgColor
        view.layer?.borderWidth = 2
        
        view.layer?.backgroundColor = NSColor.white.cgColor
        portraitView.wantsLayer = true
    }
    
    private func updateView() {
        if let firstLetter = abbrev.first,
            let colorHex = NXCommonUtils.circleViewBKColor[String(firstLetter).lowercased()] {
            portraitView.backgroundColor = NSColor(colorWithHex: colorHex)!
        }
        
        portraitView.text = abbrev
        nameLbl.stringValue = name
        emailLbl.stringValue = email
    }
    
}
