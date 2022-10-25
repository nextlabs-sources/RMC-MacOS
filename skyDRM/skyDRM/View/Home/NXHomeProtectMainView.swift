//
//  NXHomeProtectMainView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/18.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeProtectMainViewDelegate: NSObjectProtocol {
    func onProtect(info: NXSelectedFile)
}

class NXHomeProtectMainView: NSView {

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var warningLabel: NSTextField!
    fileprivate var selectFileView: NXSelectFileView?
    weak var delegate: NXHomeProtectMainViewDelegate?
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
        selectFileView?.actionDescription = NSLocalizedString("HOME_PROTECT_ACTION_DESCRIPTION", comment: "")
        protectBtn.wantsLayer = true
        protectBtn.layer?.cornerRadius = 5
        disableBtn()
        warningLabel.isHidden = true
    }
    @IBAction func onCloseImage(_ sender: Any) {
        onClose(self)
    }
    @IBAction func onClose(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    @IBAction func onProtect(_ sender: Any) {
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
        
        delegate?.onProtect(info: info)
    }
    fileprivate func enableBtn() {
        protectBtn.isEnabled = true
        protectBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        protectBtn.isBordered = false
        let titleAttr = NSMutableAttributedString(attributedString: protectBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, protectBtn.title.count))
        protectBtn.attributedTitle = titleAttr
    }
    fileprivate func disableBtn() {
        protectBtn.isEnabled = false
        protectBtn.layer?.backgroundColor = NSColor.white.cgColor
        protectBtn.isBordered = true
        let titleAttr = NSMutableAttributedString(attributedString: protectBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black], range: NSMakeRange(0, protectBtn.title.count))
        protectBtn.attributedTitle = titleAttr
    }
}

extension NXHomeProtectMainView: NXSelectFileViewDelegate {
    func onFileClick(file: NXFileBase) {
        let info: NXSelectedFile = .repositoryFile(file: file)
        delegate?.onProtect(info: info)
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

extension NXHomeProtectMainView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        onClose(self)
    }
}
