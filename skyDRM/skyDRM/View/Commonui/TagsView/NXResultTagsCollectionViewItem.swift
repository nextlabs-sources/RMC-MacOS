//
//  NXResultTagsCollectionViewItem.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2019/9/20.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import Cocoa

class  NXResultTagsCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var labesLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        
        self.labesLabel.wantsLayer = true
        self.labesLabel.cell?.wraps = true
        self.labesLabel.usesSingleLineMode = false
       // self.labesLabel.cell?.isScrollable = false
        labesLabel.maximumNumberOfLines = 0
        
//        self.view.layer?.backgroundColor = NSColor.red.cgColor
//        self.labesLabel.layer?.backgroundColor = NSColor.cyan.cgColor
       // self.tagLabel.layer?.backgroundColor = NSColor.blue.cgColor
    }
    
    func setLabelDisplay(tagString:String?) {
        guard tagString != nil else {
            self.labesLabel.stringValue = ""
            return
        }
        let finlStr = NSString.init(string: tagString!)
        let range: NSRange =  finlStr.range(of: ":")
        let attributedStr = NSMutableAttributedString.init(string: tagString!)
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.black.cgColor, range: NSMakeRange(0,range.location+1))
        self.labesLabel.attributedStringValue = attributedStr
    }
    
}
