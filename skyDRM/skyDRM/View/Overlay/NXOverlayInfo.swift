//
//  NXOverlayInfo.swift
//  skyDRM
//
//  Created by bill.zhang on 3/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import SDML

class NXOverlayInfo: NSObject {

    struct Constant {
        static let kUser        = "$(User)"
        static let kDate        = "$(Date)"
        static let kTime        = "$(Time)"
        static let kDocument    = "$(Document)"
        static let kLinebreak = "$(Break)"
        
        static let kFontTable        = ["Helvetica":"Sitka Text"]
    }
    
    var fileName:String?
    var text:String
    var font:NSFont
    var transparency:CGFloat
    var textColor :NSColor
    var isClockwiserotation:Bool
    
    var density:String?
    var isRepeat:Bool?
    
    init(text: String) {
        self.text = NXOverlayInfo.parseObligation(text: text)
        
        if let watermark = NXClient.getCurrentClient().getFullWatermark() {
            font = NXOverlayInfo.parseFont(fontName: watermark.getFontName(), fontSize: CGFloat(watermark.getFontSize()))
            transparency = CGFloat(watermark.getTransparency())
            textColor = NXOverlayInfo.parseColor(rgbColor: watermark.getFontColor(), transParent:CGFloat(watermark.getTransparency()))
            isClockwiserotation = (watermark.getRotation() == .clockwise)
            
        } else {
            font = NSFont.systemFont(ofSize: 26)
            transparency = 70
            textColor = NXOverlayInfo.parseColor(rgbColor: "#FF0000", transParent: transparency)
            isClockwiserotation = true
        }
    }
    
    init(_ fileName: String?) {
        self.fileName = fileName
        
        if let watermark = NXClient.getCurrentClient().getFullWatermark() {
            text = NXOverlayInfo.parseObligation(text: watermark.getText())
            font = NXOverlayInfo.parseFont(fontName: watermark.getFontName(), fontSize: CGFloat(watermark.getFontSize()))
            transparency = CGFloat(watermark.getTransparency())
            textColor = NXOverlayInfo.parseColor(rgbColor: watermark.getFontColor(), transParent:CGFloat(watermark.getTransparency()))
            isClockwiserotation = (watermark.getRotation() == .clockwise)
            
        } else {
            text = "nextlabs.com.overlay"
            font = NSFont.systemFont(ofSize: 26)
            transparency = 70
            textColor = NXOverlayInfo.parseColor(rgbColor: "#FF0000", transParent: transparency)
            isClockwiserotation = true
        }
    }
    
    class func parseObligation(text:String)->String {
        let user = NXClientUser.shared.user
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormater.string(from: Date())
        dateFormater.dateFormat = "HH:mm:ss"
        let timeStr = dateFormater.string(from: Date())
        
        var temp = text.replacingOccurrences(of: Constant.kUser, with: user!.email, options: .literal, range: nil)
        temp = temp.replacingOccurrences(of: Constant.kDate, with: dateStr, options: .literal, range: nil)
        temp = temp.replacingOccurrences(of: Constant.kTime, with: timeStr, options: .literal, range: nil)
        temp = temp.replacingOccurrences(of: Constant.kDocument, with: timeStr, options: .literal, range: nil)
        
        temp = temp.replacingOccurrences(of: "\\n", with: "\n", options: .literal, range: nil)
        
        temp = temp.replacingOccurrences(of: Constant.kLinebreak, with: "\n", options: .literal, range: nil)
        
        return temp.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    class func parseFont(fontName:String,fontSize:CGFloat)->NSFont{
        //for now only have Helvetica font, so we use mac system fontname replace
        return NSFont.systemFont(ofSize: fontSize)
    }
    
    class func parseColor(rgbColor:String, transParent:CGFloat)->NSColor {
        let color = NSColor.color(withHexColor: rgbColor)
        
        return NSColor(deviceRed: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 1-transParent/100.0)
    }
}
