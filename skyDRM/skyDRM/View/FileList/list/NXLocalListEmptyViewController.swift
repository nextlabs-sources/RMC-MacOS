//
//  NXLocalListEmptyViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 20/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXLocalListEmptyViewControllerDelegate: class {
    func protect()
    func share()
}

class NXLocalListEmptyViewController: NSViewController {

    @IBOutlet weak var protectView: NSView!
    @IBOutlet weak var shareView: NSView!
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var shareBtn: NSButton!
    @IBOutlet weak var protectLbl: NSTextField!
    @IBOutlet weak var shareLbl: NSTextField!
    @IBOutlet weak var shareAndProtect: NSTextField!
    @IBOutlet weak var protect: NSTextField!
    weak var delegate: NXLocalListEmptyViewControllerDelegate?
    
    @IBAction func protect(_ sender: Any) {
        delegate?.protect()
    }
    
    @IBAction func share(_ sender: Any) {
        delegate?.share()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        location()
        initView()
    
    }
    // MARK: internationalization suitable
    fileprivate func location() {
        protectBtn.title = "LOCAL_MAIN_TABLE_EMPTY_PROTECT".localized
        shareBtn.title =  "LOCAL_MAIN_TABLE_EMPTY_PROTECT_SHARE".localized
        protect.stringValue = "LOCAL_MAIN_TABLE_EMPTY_PROTECT_TEXT".localized
        shareAndProtect.stringValue = "LOCAL_MAIN_TABLE_ENPTY_PROTECT_SHARE_TEXT".localized
    }
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    func initView() {
        changeButtonDisplay()
        changeLabelDisplay()
    }
    
    func changeLabelDisplay() {
        let protectAttri = createAttriStrForLbl(str: "LOCAL_MAIN_TABLE_EMPTY_PROTECT_FILE_DESCRIPTION".localized)
        let mutableAttri = NSMutableAttributedString(attributedString: protectAttri)
        let range = NSRange(location: protectAttri.length - 8, length: 7)
        mutableAttri.addAttribute(.foregroundColor, value: NSColor.blue, range: range)
        protectLbl.attributedStringValue = mutableAttri
        
        let shareAttri = createAttriStrForLbl(str: "LOCAL_MAIN_TABLE_EMPTY_SHARE_FILE_DESCRIPTION".localized)
        shareLbl.attributedStringValue = shareAttri
    }
    
    func createAttriStrForLbl(str: String) -> NSAttributedString {
        let attriStr = NSMutableAttributedString(string: str)
        attriStr.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.init(colorWithHex: "#828282")!, range: NSRange.init(location: 0, length: attriStr.length - 1))
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        attriStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange.init(location: 0, length: attriStr.length))
        return attriStr
    }

    func changeButtonDisplay() {
        protectBtn.wantsLayer = true
        protectBtn.layer?.cornerRadius = 5
        let protectLayer = createGradientLayer(with: protectBtn.bounds)
        protectBtn.layer?.addSublayer(protectLayer)
        
        // Change attributeString
        let protectBtnTitle = NSMutableAttributedString(attributedString: protectBtn.attributedTitle)
        protectBtnTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.white, range: NSRange.init(location: 0, length: protectBtnTitle.length))
        protectBtn.attributedTitle = protectBtnTitle
        
        shareBtn.wantsLayer = true
        shareBtn.layer?.cornerRadius = 5
        let shareLayer = createGradientLayer(with: shareBtn.bounds)
        shareBtn.layer?.addSublayer(shareLayer)
        // Change attributeString
        let shareBtnTitle = NSMutableAttributedString(attributedString: shareBtn.attributedTitle)
        shareBtnTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.white, range: NSRange.init(location: 0, length: shareBtnTitle.length))
        shareBtn.attributedTitle = shareBtnTitle
    }
    
    func createGradientLayer(with frame: CGRect) -> CALayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [NSColor(colorWithHex: "#6AB3FA")!.cgColor, NSColor(colorWithHex: "#087FFF")!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = frame
        
        return gradientLayer
    }
}
