//
//  NXAddFileSelectNewProjectViewItem.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2019/9/18.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import Cocoa

class  NXAddFileSelectNewProjectViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var fileNameLabel: NSTextField!
    
    @IBOutlet weak var lineView: NSView!
    
    @IBOutlet weak var rightsDescText: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.rightsDescText.stringValue = "Protected with company defined rights"
        lineView.wantsLayer = true
        lineView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        fileNameLabel.wantsLayer = true
        
        fileNameLabel.maximumNumberOfLines = 0
        //
               self.view.layer?.backgroundColor = NSColor.white.cgColor
        //         self.labelsLabel.layer?.backgroundColor = NSColor.cyan.cgColor
        //          self.tagLabel.layer?.backgroundColor = NSColor.blue.cgColor
    }
    
    public func setFileName(fileName:String?){
        guard fileName != nil else {
             fileNameLabel.stringValue = ""
            return
        }
        fileNameLabel.stringValue = fileName!
    }
}



