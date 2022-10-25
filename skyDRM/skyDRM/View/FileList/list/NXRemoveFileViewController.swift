
//
//  NXRemoveFileViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 16/01/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

protocol NXRemoveFileVCDelegate: NSObjectProtocol {
    func delete(file: NXFile)
}

class NXRemoveFileViewController: NSViewController {
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var sizeLabel: NSTextField!
    @IBOutlet weak var modifiedLabel: NSTextField!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var deleteBtn: NSButton!
    
    weak var file: NXFile? {
        didSet {
            if let file = file {
                DispatchQueue.main.async {
                    self.nameLabel.stringValue = file.name
                    self.sizeLabel.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
                    self.modifiedLabel.stringValue = file.lastModifiedTime
                }
            }
        }
    }
    
    weak var delegate: NXRemoveFileVCDelegate?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = NSLocalizedString("REMOVE_FILE_WINDOW_TITLE", comment: "")
        self.view.window?.styleMask = [.titled, .closable]
        self.view.window?.backgroundColor = NSColor.white
        self.view.window?.titlebarAppearsTransparent = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.borderWidth = 0.3
        
        deleteBtn.wantsLayer = true
        deleteBtn.layer?.cornerRadius = 5
        deleteBtn.layer?.backgroundColor = NSColor.color(withHexColor: "#EB5757").cgColor
        let titleAttr = NSMutableAttributedString(attributedString: deleteBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, deleteBtn.title.count))
        deleteBtn.attributedTitle = titleAttr
        
        self.view.window?.delegate = self
    }
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(self)
    }
    @IBAction func onDelete(_ sender: Any) {
        if let file = file {
            delegate?.delete(file: file)
        }
    }
    
}
extension NXRemoveFileViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.presentingViewController?.dismiss(self)
    }
}
