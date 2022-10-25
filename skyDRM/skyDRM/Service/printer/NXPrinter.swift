//
//  NXPrinter.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/13/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXPrinter: NSObject {
    var filePath:String
    var printInfo:NSPrintInfo
    
    var watermark:NXWatermark?
    
    init(file filePath:String) {
        self.filePath = filePath
        self.printInfo = NSPrintInfo.shared
        super.init()
        //self.commonInit()
    }
    
    class func supportPrint(_ filePath:String)-> Bool {
        var error : NSError?
        if NXCommonUtils.getExtension(fullpath: filePath, error: &error) == "xlt" {
            return false
        }
        
        guard let mimeType = NXCommonUtils.getMimeType(filepath: filePath) else {
            return false
        }
        
        if mimeType.hasPrefix("text/") || mimeType.hasPrefix("image/") || mimeType.hasPrefix("application/pdf") || mimeType.hasPrefix("application/xml") || mimeType.hasPrefix("application/octet-stream") {
            return true
        } else {
            return false
        }
    }
    
    class func createPrinter(filePath:String?)-> NXPrinter? {
        guard let localPath = filePath else {
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: localPath) else {
            return nil
        }
        
        guard let mimeType =  NXCommonUtils.getMimeType(filepath: localPath) else {
            return nil
        }
        
        var printer:NXPrinter? = nil
        
        if (mimeType.hasPrefix("text/") || mimeType.hasPrefix("application/xml") || mimeType.hasPrefix("application/octet-stream")) {
            printer = NXPlaintextPrinter(file: localPath)
        }
        
        if mimeType.hasPrefix("application/pdf") {
            printer = NXPDFPrinter(file: localPath)
            printer?.commonInit()
        }
        
        if mimeType.hasPrefix("image/") {
            printer = NXPhotoPrinter(file: localPath)
            printer?.commonInit()
        }
        
        return printer;
    }
    
    func print(window: NSWindow, overlayInfo:NXOverlayInfo?)->Bool {
        assert(true)
        return false
    }
    
    private func commonInit() {
        self.printInfo.isHorizontallyCentered = true
        self.printInfo.topMargin = 20;
        self.printInfo.bottomMargin = 20
        self.printInfo.leftMargin = 20
        self.printInfo.rightMargin = 20
    }
}
