//
//  NXPlaintextPrinter.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/13/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXPlaintextPrinter: NXPrinter {

    var textView:NXPrinterTextView?
    
    override func print(window: NSWindow, overlayInfo: NXOverlayInfo?) -> Bool {
        if FileManager.default.fileExists(atPath: filePath) == false {
            return false
        }
        if overlayInfo != nil {
            self.watermark = NXWatermark(overlayInfo: overlayInfo!)
        }
        
        let frame = CGRect(x: 0, y: 0, width: self.printInfo.paperSize.width - self.printInfo.leftMargin - self.printInfo.rightMargin - 20, height: self.printInfo.paperSize.height - self.printInfo.topMargin - self.printInfo.bottomMargin-20)
        textView = NXPrinterTextView(frame:frame)
        textView?.watermark = self.watermark
        
        if textView?.readRTFD(fromFile: filePath) == false {
            return false
        }
        
        self.printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
        self.printInfo.isVerticallyCentered = false
        self.printInfo.horizontalPagination = NSPrintInfo.PaginationMode.fit
        
        let printOperation = NSPrintOperation(view: textView!, printInfo: self.printInfo)
        DispatchQueue.main.async {
            printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        }
        return true
    }
}
