//
//  NXTagsDisplayViewItem.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2019/9/18.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import Cocoa

class  NXTagsDisplayViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var rightsTagLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        rightsTagLabel.wantsLayer = true
        rightsTagLabel.maximumNumberOfLines = 0
        //
        self.view.layer?.backgroundColor = NSColor.white.cgColor
//                self.rightsTagLabel.backgroundColor = NSColor.cyan
//                self.rightsTagLabel.layer?.backgroundColor = NSColor.orange.cgColor
//                 self.labelsLabel.layer?.backgroundColor = NSColor.cyan.cgColor
//                  self.tagLabel.layer?.backgroundColor = NSColor.blue.cgColor
    }
    
    func setRightsLabelDisplay(rightsTagDisplay:String?) {
        guard rightsTagDisplay != nil else {
            self.rightsTagLabel.stringValue = ""
            return
        }
        let finlStr = NSString.init(string: rightsTagDisplay!)
        let range: NSRange =  finlStr.range(of: ":")
        let attributedStr = NSMutableAttributedString.init(string: rightsTagDisplay!)
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.black.cgColor, range: NSMakeRange(0,range.location+1))
        self.rightsTagLabel.attributedStringValue = attributedStr
    }
}
