//
//  NXUploadLocalView.swift
//  SkyDrmUITest
//
//  Created by Walt (Shuiping) Li on 2017/5/17.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXUploadLocalViewDelegate: NSObjectProtocol {
    func onLocalFileSelectChange(bSelected: Bool)
}

class NXUploadLocalView: NSView {

    @IBOutlet weak var browserBtn: NSButton!
    @IBOutlet weak var pathLabel: NSTextField!
    @IBOutlet weak var actionLabel: NSTextField!
    @IBOutlet weak var destinationView: NXDragDropDestinationView!
    var fileURL: URL? {
        willSet {
            if let string = newValue?.path {
                pathLabel.stringValue = string
            }
            else {
                pathLabel.stringValue = ""
            }
        }
        didSet {
            if let _ = fileURL {
                delegate?.onLocalFileSelectChange(bSelected: true)
            }
            else {
                delegate?.onLocalFileSelectChange(bSelected: false)
            }
        }
    }
    var actionDescription = "" {
        didSet {
            actionLabel.stringValue = actionDescription
        }
    }
    weak var delegate: NXUploadLocalViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        let dashHeight: CGFloat = 1
        let dashLength: CGFloat = 10
        let dashColor: NSColor = .gray
        
        // setup the context
        let currentContext = NSGraphicsContext.current!.cgContext
        currentContext.setLineWidth(dashHeight)
        currentContext.setLineDash(phase: 0, lengths: [dashLength])
        currentContext.setStrokeColor(dashColor.cgColor)
        
        // draw the dashed path
        currentContext.addRect(bounds.insetBy(dx: dashHeight, dy: dashHeight))
        currentContext.strokePath()
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        destinationView.delegate = self
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        let titleAttr = NSMutableAttributedString(attributedString: browserBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#2F80ED", alpha: 1.0)!], range: NSMakeRange(0, browserBtn.title.count))
        browserBtn.attributedTitle = titleAttr
    }
    @IBAction func onBrowser(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        guard let window = self.window else {
            return
        }
        openPanel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else {
                    return
                }
                
                do {
                    if let filePath = openPanel.url?.path {
                        let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary?
                        if attr?.fileSize() == 0 {
                            NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                            })
                            return
                        }
                    }
                } catch {
                    
                }
                
                self.fileURL = url
            }
        }

    }
    
}
extension NXUploadLocalView: NXDragDropDestinationViewDelegate {
    func getURLs(_ urls: [URL]) {
        if urls.count > 0 {
            fileURL = urls[0]
        }
    }
}
