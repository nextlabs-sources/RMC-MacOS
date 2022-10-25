//
//  NXRightsView.swift
//  skyDRM
//
//  Created by bill.zhang on 3/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXRightsView: NSView {
    
    @IBOutlet weak var expiryChangeLabel: NXMouseEventTextField!
    @IBOutlet weak var watermarkChangeLabel: NXMouseEventTextField!
    @IBOutlet weak var watermarkDescriptionLabel: NSTextField!
    @IBOutlet weak var expiryDescriptionLabel: NSTextField!
    @IBOutlet weak var checkPrint: NSButton!
    @IBOutlet weak var checkOverlay: NSButton!
    @IBOutlet weak var checkShare: NSButton!
    @IBOutlet weak var checkSaveAs: NSButton!
    @IBOutlet weak var checkExtract: NSButton!
    @IBOutlet weak var checkEdit: NSButton!
    @IBOutlet weak var promptLabel: NSTextField!
    @IBOutlet weak var Collaboration: NSTextField!
    @IBOutlet weak var effect: NSTextField!
    @IBOutlet weak var expirationBtn: NSTextField!
    @IBOutlet weak var vilidity: NSButton!
    @IBOutlet weak var checkView: NSButton!
    @IBOutlet weak var contenText: NSTextField!
    fileprivate var watermarkVC: NXWatermarkEditVC?
    fileprivate var expiryVC: NXExpiryEditVC?
    
    fileprivate var rightTypes = Set<NXRightType>()
    
    fileprivate var watermark: NXFileWatermark?
    fileprivate var expiry: NXFileExpiry?
    
    // Input
    func set(watermark: NXFileWatermark?, expiry: NXFileExpiry?) {
        guard let watermark = watermark, let expiry = expiry else {
            return
        }
        
        self.watermark = watermark
        self.expiry = expiry
        
        // Refresh UI.
        expiryDescriptionLabel.stringValue = expiry.description
        watermarkDescriptionLabel.stringValue = watermark.text
        
    }
    
    // Output.
    var rights: NXRightObligation {
        get {
            let right = NXRightObligation()
            right.rights = rightTypes.sorted { (left, right) -> Bool in
                return left.rawValue < right.rawValue
            }
            if rightTypes.contains(.watermark) {
                right.watermark = watermark
            }
            
            right.expiry = expiry
            return right
        }
    }
    
    fileprivate func location() {
        promptLabel.stringValue = "FILE_RIGHT_PROMPT".localized
        checkPrint.title = "FILE_RIGHT_PRINT".localized
        checkShare.title = "FILE_RIGHT_Share".localized
        checkEdit.title =  "FILE_RIGHT_EDIT".localized
        checkExtract.title = "FILE_RIGHT_EXTRACT".localized
        checkSaveAs.title = "FILE_RIGHT_SAVEAS".localized
        Collaboration.stringValue = "FILE_RIGHT_COLLABORATION".localized
        effect.stringValue = "FILE_RIGHT_EFFECT".localized
        expirationBtn.stringValue = "FILE_RIGHT_EXPIRATION".localized
        contenText.stringValue = "FILE_RIGHT_CONTENT".localized
        checkView.title = "FILE_RIGHT_VIEW".localized
        checkOverlay.title = "FILE_RIGHT_WATERMARK".localized
        watermarkChangeLabel.stringValue = "FILE_RIGHT_MOUSEEVENT_CHANGE".localized
        vilidity.title = "FILE_RIGHT_EXPIRATION".localized
        expiryDescriptionLabel.stringValue = "FILE_RIGHT_VALIDITY_NAVER".localized
        expiryChangeLabel.stringValue = "FILE_RIGHT_MOUSEEVENT_CHANGE".localized
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let _ = self.window else {
            return
        }
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.init(colorWithHex: "#ECECEC")?.cgColor
        layer?.borderColor = NSColor.init(colorWithHex: "#BDBDBD")?.cgColor
        layer?.borderWidth = 0.5
        
        underlineLabel(textfield: expiryChangeLabel)
        underlineLabel(textfield: watermarkChangeLabel)
        expiryChangeLabel.mouseDelegate = self
        watermarkChangeLabel.mouseDelegate = self
        watermarkDescriptionLabel.isHidden = true
        watermarkChangeLabel.isHidden = true
        location()
        debugPrint(rights)
        rightTypes.insert(.view)
        
        

    }
    
    @IBAction func printRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            rightTypes.insert(.print)
        } else {
            rightTypes.remove(.print)
        }
    }
    
    @IBAction func shareRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on  {
            rightTypes.insert(.share)
        } else {
            rightTypes.remove(.share)
        }
    }
    
    @IBAction func editRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            rightTypes.insert(.edit)
        } else {
            rightTypes.remove(.edit)
        }
    }
    @IBAction func extractRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            rightTypes.insert(.extract)
        } else {
            rightTypes.remove(.extract)
        }
    }
    
    @IBAction func saveAsRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on  {
            rightTypes.insert(.saveAs)
        } else {
            rightTypes.remove(.saveAs)
        }
    }
    
    @IBAction func watermarkRightSelected(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            rightTypes.insert(.watermark)
            watermarkDescriptionLabel.isHidden = false
            watermarkChangeLabel.isHidden = false
        } else {
            rightTypes.remove(.watermark)
            watermarkDescriptionLabel.isHidden = true
            watermarkChangeLabel.isHidden = true
        }
    }

    private func underlineLabel(textfield: NSTextField) {
        let attr = NSAttributedString(string: textfield.stringValue)
        let mutableAttr = NSMutableAttributedString(attributedString: attr)
        mutableAttr.addAttributes([NSAttributedString.Key.underlineStyle: NSNumber(value: Int8(NSUnderlineStyle.single.rawValue))], range: NSMakeRange(0, textfield.stringValue.count))
        mutableAttr.addAttributes([NSAttributedString.Key.underlineColor: textfield.textColor ?? NSColor.black], range: NSMakeRange(0, textfield.stringValue.count))
        textfield.attributedStringValue = mutableAttr
    }
}

extension NXRightsView: NXMouseEventTextFieldDelegate {
    func mouseDownTextField(sender: Any, event: NSEvent) {
        guard let control = sender as? NXMouseEventTextField else {
            return
        }
        if control == watermarkChangeLabel {
            let vc = NXWatermarkEditVC()
            vc.delegate = self
            self.window?.contentViewController?.presentAsModalWindow(vc)
            vc.watermark = (watermark)!
            watermarkVC = vc
        }
        else if control == expiryChangeLabel {
            let vc = NXExpiryEditVC()
            vc.delegate = self
            self.window?.contentViewController?.presentAsModalWindow(vc)
            vc.expiry = (expiry)!
            expiryVC = vc
        }
    }
}

extension NXRightsView: NXWatermarkEditVCDelegate {
    func onSelect(watermark: NXFileWatermark) {
        self.watermark = watermark
        watermarkDescriptionLabel.stringValue = watermark.text
    }
    
    func onClose() {
    }
}

extension NXRightsView: NXExpiryEditVCDelegate {
    func onSelect(expiry: NXFileExpiry) {
        self.expiry = expiry
        expiryDescriptionLabel.stringValue = expiry.description
    }
    
}
