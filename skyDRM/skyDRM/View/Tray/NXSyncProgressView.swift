//
//  NXSyncProgressView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSyncProgressView: NSView {
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var image: NSImageView!
    
    var progress = Progress() {
        didSet {
            needsDisplay = true
            DispatchQueue.main.async {
                let state = String(format: NSLocalizedString("SYNC_STATUS_UPLOADING", comment: ""), self.progress.completedUnitCount, self.progress.totalUnitCount)
                self.label.stringValue = state
            }
        }
    }
    private struct Constant {
        static let leftGapIndicator: CGFloat = 15
        static let rightGapIndicator: CGFloat = 20
        static let totalColor = NSColor(colorWithHex: "#B2C4E5", alpha: 1.0)!
        static let completedColor = NSColor(colorWithHex: "#4468B1", alpha: 1.0)!
        static let pendingColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)!
        static let heightIndicator: CGFloat = 6
    }
    private var indicatorFrame = NSZeroRect
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        context?.clip(to: indicatorFrame)
        //draw total
        NXGraphic.drawRoundedRect(rect: indicatorFrame, inContext: context, radius: indicatorFrame.height/3, borderColor: Constant.totalColor.cgColor, fillColor: Constant.totalColor.cgColor)
        
        //draw completed
        let total = CGFloat(progress.totalUnitCount)
        if total != 0 {
            let completed = CGFloat(progress.completedUnitCount)
            let completedWidth: CGFloat = indicatorFrame.width * completed / total
            if completedWidth != 0 {
                let completedFrame = NSMakeRect(indicatorFrame.minX, indicatorFrame.minY, completedWidth, indicatorFrame.height)
                NXGraphic.drawRoundedRect(rect: completedFrame, inContext: context, radius: completedFrame.height/3, borderColor: Constant.completedColor.cgColor, fillColor: Constant.completedColor.cgColor)
            }
        }
        context?.restoreGState()
        
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        indicatorFrame = NSMakeRect(Constant.leftGapIndicator, frame.height/2 - Constant.heightIndicator/2, label.frame.minX - Constant.rightGapIndicator - Constant.leftGapIndicator, Constant.heightIndicator)
        let state = String(format: NSLocalizedString("SYNC_STATUS_UPLOADING", comment: ""), 0, 0)
        self.label.stringValue = state
    }
    
}
