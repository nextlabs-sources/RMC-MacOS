//
//  NXHomeShareMainView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeShareMainViewDelegate: NSObjectProtocol {
    func onShare(info: NXSelectedFile)
}

class NXHomeShareMainView: NSView {

    @IBOutlet weak var proceedBtn: NSButton!
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var warningLabel: NSTextField!
    fileprivate var selectFileView: NXSelectFileView?
    weak var delegate: NXHomeShareMainViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        self.window?.delegate = self
        
        selectFileView = NXCommonUtils.createViewFromXib(xibName: "NXSelectFileView", identifier: "selectFileView", frame: nil, superView: contentView) as? NXSelectFileView
        selectFileView?.delegate = self
        selectFileView?.actionDescription = NSLocalizedString("HOME_SHARE_ACTION_DESCRIPTION", comment: "")
        proceedBtn.wantsLayer = true
        proceedBtn.layer?.cornerRadius = 5
        disableBtn()
        warningLabel.isHidden = true
        
    }
    @IBAction func onCloseImage(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    @IBAction func onShare(_ sender: Any) {
        guard let info = selectFileView?.selectedFile else{
            return
        }
        
        switch info {
        case .repositoryFile(let file):
            if !NXCommonUtils.isGoogleDriveTypeFile(file: file) && file?.size == 0 {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                })
                return
            }
            break
        default:
            break
        }
        
        delegate?.onShare(info: info)
    }
    fileprivate func enableBtn() {
        proceedBtn.isEnabled = true
        proceedBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        proceedBtn.isBordered = false
        let titleAttr = NSMutableAttributedString(attributedString: proceedBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, proceedBtn.title.count))
        proceedBtn.attributedTitle = titleAttr
    }
    fileprivate func disableBtn() {
        proceedBtn.isEnabled = false
        proceedBtn.layer?.backgroundColor = NSColor.white.cgColor
        proceedBtn.isBordered = true
        let titleAttr = NSMutableAttributedString(attributedString: proceedBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black], range: NSMakeRange(0, proceedBtn.title.count))
        proceedBtn.attributedTitle = titleAttr
    }
}

extension NXHomeShareMainView: NXSelectFileViewDelegate {
    func onFileClick(file: NXFileBase) {
        let info: NXSelectedFile = .repositoryFile(file: file)
        delegate?.onShare(info: info)
    }
    func onSelectChange(bSelected: Bool) {
        if bSelected == false {
            disableBtn()
            warningLabel.isHidden = true
        }
        else {
            if let selected = selectFileView?.selectedFile {
                switch selected {
                case .localFile(let url):
                    var isDir: ObjCBool = ObjCBool(false)
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                        isDir.boolValue == true {
                        disableBtn()
                        NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("SELECT_FILE_WARNING", comment: ""))
                        return
                    }
                default:
                    break
                }
            }
            enableBtn()
            warningLabel.isHidden = true
        }
    }
}

extension NXHomeShareMainView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.onCancel(self)
    }
}
