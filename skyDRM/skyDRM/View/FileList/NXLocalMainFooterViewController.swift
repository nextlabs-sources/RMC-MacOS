 //
//  NXLocalMainFooterViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 17/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXLocalMainFooterViewControllerDelegate: class {
    func getItemCount() -> Int
    
}

class NXLocalMainFooterViewController: NSViewController {

    @IBOutlet weak var itemCountLbl: NSTextField!
    @IBOutlet weak var statusLbl: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    @IBOutlet weak var uploadScheduleLbl: NSTextField!
    @IBOutlet weak var uploadSettingLbl: NSTextField!
    @IBOutlet weak var changeBtn: NSButton!
    
    weak var delegate: NXLocalMainFooterViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        changeAppearence()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let itemCount = delegate?.getItemCount() {
            displayItemCount(with: itemCount)
        }
        
        // Display network status
        updateNetworkStatus()
    }
    
    deinit {
    }
    
    func changeAppearence() {
        let grayAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.init(colorWithHex: "#828282")!]
        uploadScheduleLbl.attributedStringValue = NSAttributedString(string: uploadScheduleLbl.stringValue, attributes: grayAttriDic)
        statusLbl.attributedStringValue = NSAttributedString(string: statusLbl.stringValue, attributes: grayAttriDic)
        
        let blueAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.systemBlue]
        changeBtn.attributedTitle = NSAttributedString(string: changeBtn.title, attributes: blueAttriDic)
        
    }
    
    func displayItemCount(with itemCount: Int) {
        if itemCount > 1 {
            itemCountLbl.stringValue = String.init(format: "LOCAL_MAIN_FOOTER_ITEMS".localized, itemCount)
        } else {
            itemCountLbl.stringValue = String.init(format: "LOCAL_MAIN_FOOTER_ITEM".localized, itemCount)
        }
    }
    
    func updateNetworkStatus() {
        let status = NXClientUser.shared.isOnline
        displayNetworkStatus(with: status)
    }
    
    func displayNetworkStatus(with isConnect: Bool) {
        if isConnect {
            statusLbl.stringValue = "LOCAL_MAIN_FOOTER_NETWORK_STATUS_CONNECT".localized
            statusImage.image = NSImage(named:"Status-LeaveACopy")
        } else {
            statusLbl.stringValue = "LOCAL_MAIN_FOOTER_NETWORK_STATUS_DISCONNECT".localized
            statusImage.image = NSImage(named: "Status-ErrorMessage")
        }
        
        let grayAttriDic = [NSAttributedString.Key.foregroundColor: NSColor.gray]
        statusLbl.attributedStringValue = NSAttributedString(string: statusLbl.stringValue, attributes: grayAttriDic)
    }
}
