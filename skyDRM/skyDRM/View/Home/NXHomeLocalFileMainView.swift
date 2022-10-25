//
//  NXHomeLocalFileMainView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeLocalFileMainViewDelegate: NSObjectProtocol {
    func onProtect(url: URL)
    func onShare(url: URL)
}

class NXHomeLocalFileMainView: NSView {

    @IBOutlet weak var shareBtn: NSButton!
    @IBOutlet weak var protectBtn: NSButton!
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var warningLabel: NSTextField!
    fileprivate var localFileView: NXUploadLocalView?
    weak var delegate: NXHomeLocalFileMainViewDelegate?
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
        shareBtn.wantsLayer = true
        shareBtn.layer?.cornerRadius = 5
        disableBtn(btn: shareBtn)
        
        protectBtn.wantsLayer = true
        protectBtn.layer?.cornerRadius = 5
        disableBtn(btn: protectBtn)
        warningLabel.isHidden = true
        
        localFileView = NXCommonUtils.createViewFromXib(xibName: "NXUploadLocalView", identifier: "uploadLocalView", frame: nil, superView: contentView) as? NXUploadLocalView
        localFileView?.actionDescription = NSLocalizedString("HOME_LOCAL_FILE_ACTION_DESCRIPTION", comment: "")
        localFileView?.delegate = self
    }
    @IBAction func onProtect(_ sender: Any) {
        guard let info = localFileView?.fileURL else {
            return
        }
        delegate?.onProtect(url: info)
        
    }
    @IBAction func onShare(_ sender: Any) {
        guard let info = localFileView?.fileURL else {
            return
        }
        delegate?.onShare(url: info)
    }
    @IBAction func onCloseImage(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    fileprivate func enableBtn(btn: NSButton) {
        btn.isEnabled = true
        btn.layer?.backgroundColor = GREEN_COLOR.cgColor
        btn.isBordered = false
        let titleAttr = NSMutableAttributedString(attributedString: btn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, btn.title.count))
        btn.attributedTitle = titleAttr
    }
    fileprivate func disableBtn(btn: NSButton) {
        btn.isEnabled = false
        btn.layer?.backgroundColor = NSColor.white.cgColor
        btn.isBordered = true
        let titleAttr = NSMutableAttributedString(attributedString: btn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black], range: NSMakeRange(0, btn.title.count))
        btn.attributedTitle = titleAttr
    }
}

extension NXHomeLocalFileMainView: NXUploadLocalViewDelegate {
    func onLocalFileSelectChange(bSelected: Bool) {
        if bSelected == false {
            disableBtn(btn: protectBtn)
            disableBtn(btn: shareBtn)
            warningLabel.isHidden = true
        }
        else {
            guard let url = localFileView?.fileURL else {
                disableBtn(btn: protectBtn)
                disableBtn(btn: shareBtn)
                NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("SELECT_FILE_WARNING", comment: ""))
                return
            }
            var isDir: ObjCBool = ObjCBool(false)
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                isDir.boolValue == true {
                disableBtn(btn: protectBtn)
                disableBtn(btn: shareBtn)
                NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("SELECT_FILE_WARNING", comment: ""))
                return
            }
            enableBtn(btn: protectBtn)
            enableBtn(btn: shareBtn)
            warningLabel.isHidden = true
        }
    }
}
