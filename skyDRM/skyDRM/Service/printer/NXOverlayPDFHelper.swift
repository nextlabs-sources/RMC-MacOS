//
//  NXOverlayPDFHelper.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/14/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXOverlayPDFHelper: NSObject {
    var watermark:NXWatermark?
    var srcPath:String
    var dstPath:String
    init(_ srcPath:String, _ dstPath:String) {
        self.srcPath = srcPath
        self.dstPath = dstPath;
    }
    
    public func  run() -> (flag:Bool, error:NSError?) {
        let result = exportOverlayPDF()
        return (result, nil)
    }
    
    private func createPDFContext(file filePath:String, media:CGRect) -> CGContext? {
        let fileRef = CFURLCreateWithFileSystemPath(nil, filePath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        if fileRef == nil {
            return nil
        }
        var p = kCFCopyStringDictionaryKeyCallBacks
        var q = kCFTypeDictionaryValueCallBacks
        let dict = CFDictionaryCreateMutable(nil, 0, &p,  &q)
        if (dict != nil) {
            var mediaRect = media
            let pdfContext = CGContext(fileRef!, mediaBox: &mediaRect, dict)
            
            return pdfContext
        } else {
            
            return nil
        }
    }
    
    private func exportOverlayPDF() -> Bool {
        if FileManager.default.fileExists(atPath: srcPath) == false {
            return false;
        }
        
        //source file info.
        let srcPathref = CFURLCreateWithFileSystemPath(nil, srcPath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        let srcDocument = CGPDFDocument(srcPathref!)
        
        guard let page = srcDocument?.page(at: 1) else {
            return false
        }
        let mediaRec = page.getBoxRect(CGPDFBox.mediaBox)
        
        //export file context
        
        let pdfContext = createPDFContext(file: dstPath, media: mediaRec)
        
        return drawExportPDF(context: pdfContext!, srcDoc: srcDocument!)
    }
    
    private func drawExportPDF(context:CGContext,srcDoc:CGPDFDocument)->Bool {
        
        for index in 1...srcDoc.numberOfPages {
            let pdfPage = srcDoc.page(at: index)
            
            var pageRect = pdfPage?.getBoxRect(CGPDFBox.mediaBox)
            
            //draw source pdf page.
            context.beginPage(mediaBox: &pageRect!)
            context.clip(to: pageRect!)
            context.drawPDFPage(pdfPage!)
        
            guard watermark != nil else {
                continue
            }
            
            //draw overlay
            let attributeStr = self.watermark?.attributeString()
            let normalSize = self.watermark?.unitSize()
            let rotationSize = CGSize(width: (watermark?.unitWidth)!, height: (watermark?.unitHeight)!)
            
            for x in stride(from: Int((pageRect?.origin.x)!), to: Int((pageRect?.size.width)! + rotationSize.width + (watermark?.constant.kWidthSpace)!), by:Int(rotationSize.width + (watermark?.constant.kWidthSpace)!)) {
                for y in stride(from: Int((pageRect?.origin.y)!), to: Int((pageRect?.size.height)! + rotationSize.height + (watermark?.constant.kHeightSpace)!), by:Int(rotationSize.height + (watermark?.constant.kHeightSpace)!)) {
                    
                    context.saveGState()
                    
                    //rotation context.
                    var transform = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
                    transform = transform.rotated(by: CGFloat((watermark?.radianAngle)!))
                    context.concatenate(transform)
                    
                    let mutablePath = CGMutablePath()
                    mutablePath.addRect(CGRect(origin: CGPoint(x: 0, y: 0), size: normalSize!))
                    let frameSetter = CTFramesetterCreateWithAttributedString(attributeStr!)
                    let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, (attributeStr?.length)!), mutablePath, nil)
                    CTFrameDraw(frame, context)
                    
                    context.restoreGState();
                }
            }
            
            context.endPage()
        }
        
        return true
    }
}
