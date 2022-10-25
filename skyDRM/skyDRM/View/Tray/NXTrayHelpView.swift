//
//  NXTrayHelpView.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 28/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayHelpViewDelegate: NSObjectProtocol {
    func removeHelpView()
}

class NXTrayHelpView: NSView {
    
    @IBOutlet weak var headLbl: NSTextField!
    @IBOutlet weak var contentLbl: NSTextField!
    
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var openBtn: NSButton!
    
    weak var delegate: NXTrayHelpViewDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        let cancelAttrTitle = NSMutableAttributedString.init(string: cancelBtn.title)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        cancelAttrTitle.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.color(withHexColor: "#219653"), NSAttributedString.Key.paragraphStyle: para], range: NSMakeRange(0, cancelBtn.title.lengthOfBytes(using: .utf8)))
        cancelBtn.attributedTitle = cancelAttrTitle
        
        // set linear color
        openBtn.wantsLayer = true
        openBtn.layer?.cornerRadius = 4
        
        let openAttrTitle = NSMutableAttributedString.init(string: openBtn.title)
        openAttrTitle.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: para], range: NSMakeRange(0, openBtn.title.lengthOfBytes(using: .utf8)))
        openBtn.attributedTitle = openAttrTitle
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = openBtn.bounds
        gradientLayer.colors = [NSColor(colorWithHex: "#5BACFC", alpha: 1.0)!.cgColor, NSColor(colorWithHex: "#1386FF", alpha: 1.0)!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        openBtn.layer?.addSublayer(gradientLayer)
    }
    
    @IBAction func clickCancel(_ sender: Any) {
        delegate?.removeHelpView()
    }
    
    @IBAction func clickOpen(_ sender: Any) {
        delegate?.removeHelpView()
        
        NXWindowsManager.sharedInstance.openMainWindow()
        NXWindowsManager.sharedInstance.hideTray()
    }
}
