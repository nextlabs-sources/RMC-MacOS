//
//  NXFeedbackViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 16/01/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXFeedbackViewController: NSViewController {
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var submitBtn: NSButton!
    @IBOutlet weak var backgroundView: NSView!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = NXConstant.kTitle
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor(colorWithHex: "#E3E3E3")?.cgColor
        backgroundView.layer?.borderWidth = 0.5
        backgroundView.layer?.borderColor = NSColor(colorWithHex: "#BDBDBD")?.cgColor
        
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.borderWidth = 0.3
        
        submitBtn.wantsLayer = true
        submitBtn.layer?.cornerRadius = 5
        
        let startColor = NSColor(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: submitBtn.bounds, start: startColor, end: endColor)
        submitBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: submitBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, submitBtn.title.count))
        submitBtn.attributedTitle = titleAttr
        self.view.window?.delegate = self
    }
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
    @IBAction func onSubmit(_ sender: Any) {
    }
    
}
extension NXFeedbackViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.presentingViewController?.dismiss(self)
    }
}
