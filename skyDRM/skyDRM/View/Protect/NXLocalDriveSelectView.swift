//
//  NXLocalDriveSelectView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/28.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

typealias SelectPathBlock = (_ path: String?) -> ()

class NXLocalDriveSelectView: NSView {

    @IBOutlet weak var backView: NSView!
    @IBOutlet weak var pathTextField: NSTextField!
    
    @IBOutlet weak var selectPathBtn: NSButton!
    
    var pathStr: String?
    var pathBlock: SelectPathBlock?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    // ~/Library/Containers/com.nxrmc.skyDRM/Data/Library/Application Support/com.nxrmc.skyDRM/rmtest.nextlabs.solutions/skydrm.com/306/cache\
    
    open func setDisplayPath(destinatonStr:String) {
          pathTextField.stringValue = destinatonStr
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        pathTextField.lineBreakMode = .byTruncatingTail
        
        backView.wantsLayer = true
        backView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        pathTextField.isEditable = false
        if pathStr == nil {
        }else {
            pathTextField.stringValue = pathStr ?? ""
        }
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: self.selectPathBtn.bounds, start: startColor, end: endColor)
        self.selectPathBtn.wantsLayer = true
        self.selectPathBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: self.selectPathBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, self.selectPathBtn.title.count))
        self.selectPathBtn.attributedTitle = titleAttr
    }
    
    @IBAction func selectPathAction(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.worksWhenModal = true
        openPanel.allowsMultipleSelection = false
        openPanel.beginSheetModal(for: self.window!) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                YMLog(openPanel.urls)
                self.pathStr = openPanel.urls.first?.path
                self.pathTextField.stringValue = self.pathStr ?? ""
                if self.pathBlock != nil {
                    self.pathBlock!(openPanel.urls.first?.path)
                }
            }
        }
    }
    
    
}
