//
//  NXTotalIndicatorView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/27.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXTotalIndicatorView: NSView {

    @IBOutlet weak var storageLabel: NSTextField!
    @IBOutlet weak var usedLabel: NSTextField!
    @IBOutlet weak var freeLabel: NSTextField!
    @IBOutlet weak var indicatorRangeLabel: NSTextField!
    
    
    private let borderColor = NSColor(red: 212/255, green: 212/255, blue: 223/255, alpha: 1.0)
    private let roundRectGap:CGFloat = 1
    private var myDrive: Int64 = 0
    private var myVault: Int64 = 0
    private var total: Int64 = 0
    
    var mydriveColor = NSColor.white {
        willSet {
            needsDisplay = true
        }
    }
    var myvaultColor = NSColor.white {
        willSet {
            needsDisplay = true
        }
    }
    
    func drawTotalIndicator(myDrive: Int64, myVault: Int64, total: Int64) {
        self.myDrive = myDrive
        self.myVault = myVault
        self.total = total < myDrive + myVault ? (myDrive + myVault) : total
        
        indicatorRangeLabel.isHidden = true
        needsDisplay = true
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            wantsLayer = true
            layer?.borderColor = NSColor.black.cgColor
            layer?.borderWidth = 0.3
            storageLabel.stringValue = NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_STORAGE_LABEL", comment: "")
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(colorWithHex: "#F2F3F5", alpha: 1.0)!.setFill()
        __NSRectFill(dirtyRect)
        // draw whole
        let totalRect = indicatorRangeLabel.frame
        let context = NSGraphicsContext.current?.cgContext
        NXGraphic.drawRoundedRect(rect: totalRect, inContext: context,
                                  radius: totalRect.height / 2,
                                  borderColor: borderColor.cgColor,
                                  fillColor: NSColor.white.cgColor)
        let usedStr = NXCommonUtils.formatFileSize(fileSize: myDrive + myVault, precision: 1)
        let freeStr = NXCommonUtils.formatFileSize(fileSize: total - myDrive - myVault, precision: 1)
        
        usedLabel.stringValue = String(format: NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_USED", comment: ""), usedStr)
        usedLabel.sizeToFit()
        freeLabel.stringValue = String(format: NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_FREE", comment: ""), freeStr)
        freeLabel.sizeToFit()
        guard total != 0,
            myVault + myDrive <= total else {
                return
        }
        //draw mydrive
        let myDriveWidth = CGFloat(myDrive) * totalRect.width / CGFloat(total)
        var myDrvieClipRect = CGRect()
        if myDriveWidth > roundRectGap && myDriveWidth != totalRect.width{
            myDrvieClipRect = CGRect(x: totalRect.minX, y: totalRect.minY, width: myDriveWidth - roundRectGap, height: totalRect.height)
        }
        else if myDriveWidth == totalRect.width {
            myDrvieClipRect = CGRect(x: totalRect.minX, y: totalRect.minY, width: myDriveWidth, height: totalRect.height)
        }
        context?.saveGState()
        context?.clip(to: myDrvieClipRect)
        NXGraphic.drawRoundedRect(rect: totalRect, inContext: context, radius: totalRect.height / 2, borderColor: nil, fillColor: mydriveColor.cgColor)
        context?.restoreGState()
        //draw myVault
        let myVaultWidth = CGFloat(myVault) * totalRect.width / CGFloat(total)
        let myVaultClipRect = CGRect(x: myDrvieClipRect.maxX, y: totalRect.minY, width: myVaultWidth , height: totalRect.height)
        context?.saveGState()
        context?.clip(to: myVaultClipRect)
        NXGraphic.drawRoundedRect(rect: totalRect, inContext: context, radius: totalRect.height / 2, borderColor: nil, fillColor: myvaultColor.cgColor)
        context?.restoreGState()
        
    }

}
