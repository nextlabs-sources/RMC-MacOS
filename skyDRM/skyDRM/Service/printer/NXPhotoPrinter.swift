//
//  NXPhotoPrinter.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/13/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXPhotoPrinter: NXPrinter {

    override func print(window: NSWindow, overlayInfo: NXOverlayInfo?) -> Bool {
        guard let image = NSImage(contentsOfFile: filePath) else {
            return false
        }
        if overlayInfo != nil {
            self.watermark = NXWatermark(overlayInfo: overlayInfo!)
        }
        
        let frame = CGRect(x: 0, y: 0, width: self.printInfo.paperSize.width - self.printInfo.leftMargin - self.printInfo.rightMargin, height: self.printInfo.paperSize.height - self.printInfo.topMargin - self.printInfo.bottomMargin)
        
        let imageView = NXPrinterImageView(frame:frame)
        imageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        
        imageView.watermark = watermark
        imageView.image = image
        
        self.printInfo.horizontalPagination = NSPrintInfo.PaginationMode.fit
        self.printInfo.verticalPagination = NSPrintInfo.PaginationMode.fit
        
        let printOperation = NSPrintOperation(view: imageView, printInfo: self.printInfo)
        DispatchQueue.main.async {
            //printOperation.run()
            printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        }
        
        return true
    }
}
