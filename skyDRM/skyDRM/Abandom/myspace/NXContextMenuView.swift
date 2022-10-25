//
//  NXContextMenuView.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 13/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa


class NXContextMenuView: NSView {

    @IBOutlet weak var downloadBtn: NSButton!
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var shareBtn: NSButton!
    @IBOutlet weak var propertiesBtn: NSButton!
    @IBOutlet weak var deleteBtn: NSButton!
    private let ButtonConstant:CGFloat = 60
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let startColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)
        let endColor = NSColor(colorWithHex: "#70B55B", alpha: 1.0)
        let gradient = NSGradient(starting: startColor!, ending: endColor!)
        gradient?.draw(in: bounds, angle: -30)
        self.alphaValue = 0.9
        // Drawing code here.
    }

 
    override func viewDidMoveToWindow() {
        
        downloadBtn.image = NSImage(named:"downloadinmenu")
        downloadBtn.frame.size = CGSize(width: ButtonConstant, height: ButtonConstant)
        downloadBtn.layer?.cornerRadius = ButtonConstant/2
        
        protectBtn.image = NSImage(named: "protectinmenu")
        protectBtn.frame.size = CGSize(width: ButtonConstant, height: ButtonConstant)
        protectBtn.layer?.cornerRadius = ButtonConstant/2
        
        shareBtn.image = NSImage(named: "shareinmenu")
        shareBtn.frame.size = CGSize(width: ButtonConstant, height: ButtonConstant)
        shareBtn.layer?.cornerRadius = ButtonConstant/2
        
        propertiesBtn.image = NSImage(named:"fileinfomenu")
        propertiesBtn.frame.size = CGSize(width: ButtonConstant, height: ButtonConstant)
        propertiesBtn.layer?.cornerRadius = ButtonConstant/2
        
        deleteBtn.image = NSImage(named:"deleteinmenu")
        deleteBtn.frame.size = CGSize(width: ButtonConstant, height: ButtonConstant)
        deleteBtn.layer?.cornerRadius = ButtonConstant/2
        
    }
}
