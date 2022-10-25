//
//  NXPDFPrinter.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/13/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa
import Quartz

class NXPDFPrinter: NXPrinter {
    
    override func print(window: NSWindow, overlayInfo:NXOverlayInfo?)->Bool {
        
        var outPath = String(format: "%@%@", NSTemporaryDirectory(), NSURL(fileURLWithPath: filePath).lastPathComponent!);
        
        if overlayInfo != nil {
            let pdfHelper = NXOverlayPDFHelper(filePath, outPath);
            pdfHelper.watermark = NXWatermark(overlayInfo: overlayInfo!)
            let result = pdfHelper.run()
            if result.flag == false {
                //TODO
                return false
            }
        } else {
            outPath = filePath
        }
        
        if FileManager.default.fileExists(atPath: outPath) == false {
            return false
        }
        
        self.printInfo.isVerticallyCentered = true
        self.printInfo.horizontalPagination = NSPrintInfo.PaginationMode.automatic
        self.printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
        
        let pdfDoc = PDFDocument(url:URL(fileURLWithPath: outPath))
        let printOp = pdfDoc?.printOperation(for: self.printInfo, scalingMode: PDFPrintScalingMode.pageScaleDownToFit, autoRotate: false)
        //printOp?.run()
        printOp?.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        return true
    }

}
