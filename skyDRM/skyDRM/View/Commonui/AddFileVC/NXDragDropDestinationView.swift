//
//  NXDragDropDestinationView.swift
//  SkyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/18.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXDragDropDestinationViewDelegate: NSObjectProtocol {
    func getURLs(_ urls: [URL])
}

class NXDragDropDestinationView: NSView {
    
    enum Appearance {
        static let lineWidth: CGFloat = 10.0
    }
    
    private var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }

    private var acceptableTypes: [NSPasteboard.PasteboardType] {return [NSPasteboard.PasteboardType.backwarfsCompatibleURL] }

    weak var delegate: NXDragDropDestinationViewDelegate?
    
    override func awakeFromNib() {
        setup()
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        isReceivingDrag = false
        let pasteBoard = draggingInfo.draggingPasteboard
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self]) as? [URL], urls.count > 0 {
            do {
                if urls.count > 0 {
                    let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: urls[0].path) as NSDictionary?
                    if attr?.fileSize() == 0 {
                        NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                        })
                        return true
                    }
                }
            } catch {
                
            }
            
            delegate?.getURLs(urls)
            return true
        }
        return false
        
    }
    override func draw(_ dirtyRect: NSRect) {
        if isReceivingDrag {
            NSColor.selectedControlColor.set()
            let path = NSBezierPath(rect:bounds)
            path.lineWidth = Appearance.lineWidth
            path.stroke()
        }
    }
    
    private func setup() {
        registerForDraggedTypes(acceptableTypes)
    }
    
    private func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        return true
    }
}

