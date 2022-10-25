//
//  NXRightsSelectViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXRightsSelectViewControllerDelegate: NSObjectProtocol {
    func selectFinish(with rights: NXLRights?)
    func cancel()
}

class NXRightsSelectViewController: NSViewController {

    // Input
    var fileName: String?
    
    @IBOutlet weak var rightsSelectView: NXRightsView!
    
    @IBOutlet weak var fileNameTextField: NSTextField!
    
    private struct Constant {
        static let rightsViewNibName = "NXRightsView"
        static let rightsViewIdentifier = "rightsView"
        
        static let title = NSLocalizedString("RIGHTS_SELECT_TITLE", comment: "")
    }
    
    weak var delegate: NXRightsSelectViewControllerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        rightsSelectView = NXCommonUtils.createViewFromXib(xibName: Constant.rightsViewNibName, identifier: Constant.rightsViewIdentifier, frame: rightsSelectView.frame, superView: view) as? NXRightsView
        // Init watermark and expiry from preference.
        var watermark: NXFileWatermark?
        var expiry: NXFileExpiry?
        if let text = NXClient.getCurrentClient().getUserPreference()?.getDefaultWatermark().getText() {
            watermark = NXFileWatermark(text: text)
        }
        if let preferenceExpiry = NXClient.getCurrentClient().getUserPreference()?.getDefaultExpiry() {
            expiry = NXCommonUtils.transform(from: preferenceExpiry)
        }
        rightsSelectView?.set(watermark: watermark, expiry: expiry)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        fileNameTextField.stringValue = fileName ?? ""
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.title = Constant.title
        _ = self.view.window?.styleMask.remove(.closable)
        _ = self.view.window?.styleMask.remove(.resizable)
    }
    
    @IBAction func clickOKBtn(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func clickCancelBtn(_ sender: Any) {
        self.delegate?.cancel()
        closeWindow()
    }
    
    func closeWindow() {
        NSApp.stopModal()
    }
}
