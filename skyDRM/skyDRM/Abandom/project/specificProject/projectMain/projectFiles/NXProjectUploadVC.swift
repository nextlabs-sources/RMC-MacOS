//
//  NXProjectUploadVC.swift
//  skyDRM
//
//  Created by bill.zhang on 3/6/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProjectUploadVCDelegate: NSObjectProtocol  {
    func uploadAction(forLocalPath localPath:URL?, rights:NXLRights?)
}

class NXProjectUploadVC: NSViewController {

    @IBOutlet weak var rightsContainer: NSView!
    
    @IBOutlet weak var uploadButton: NSButton!
    
    @IBOutlet weak var titleButton: NSButton!
    
    @IBAction func changeFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                do {
                    if let filePath = openPanel.url?.path {
                        let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary?
                        if attr?.fileSize() == 0 {
                            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_UPLOAD_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                            })
                            return
                        }
                    }
                } catch {
                    
                }
                
                self.localPath = openPanel.url
                self.titleButton.title = (self.localPath?.path)!
            }
        }
    }
    @IBAction func uploadButton(_ sender: Any) {
        guard localPath != nil else {
            return
        }
        //TODO if NXL File, can not protect and upload

        self.presentingViewController?.dismiss(self)
    }
    weak var delegate : NXProjectUploadVCDelegate?
    var _localPath : URL?
    var localPath : URL? {
        set {
            _localPath = newValue
            self.title = NSLocalizedString("Upload File", comment: "")
        }
        get {
            return _localPath
        }
    }
    var rightsView : NXRightsView?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        titleButton.title = (localPath?.path)!
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.styleMask = [.titled, .closable, .miniaturizable]
        self.view.window?.delegate = self
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rightsView = NXCommonUtils.createViewFromXib(xibName: "NXRightsView", identifier: "rightsView", frame: rightsContainer.bounds, superView: rightsContainer) as! NXRightsView?
        let rights = NXLRights()
        rights.setRight(.NXLRIGHTVIEW, value: true)
        
        rightsView?.translatesAutoresizingMaskIntoConstraints = false
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsView!, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsView!, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0))
        rightsContainer.addConstraint(NSLayoutConstraint(item: rightsView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: rightsContainer, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0))
        
        rightsView?.checkShare.state = NSControl.StateValue.off
        rightsView?.checkShare.isEnabled = false
        
        uploadButton.wantsLayer = true
        uploadButton.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        uploadButton.layer?.cornerRadius = 4
        uploadButton.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        uploadButton.layer?.borderWidth = 1
        uploadButton.stringValue = "Upload"
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let titleAttr = NSMutableAttributedString(attributedString: uploadButton.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, uploadButton.title.count))
        uploadButton.attributedTitle = titleAttr
        
        titleButton.wantsLayer = true
        titleButton.layer?.backgroundColor = NSColor.white.cgColor
        
    }
    
}

extension NXProjectUploadVC: NSWindowDelegate {
    private func windowShouldClose(_ sender: Any) -> Bool {
        rightsView?.removeFromSuperview()
        self.presentingViewController?.dismiss(self)
        return true
    }
}
